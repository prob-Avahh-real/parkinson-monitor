// ============================================================
// daily-analysis — 每日分析 Edge Function
// 定时：每天 21:00（由 pg_cron 触发）
// 功能：拉取当天所有用户的 events → 调用 DeepSeek → 写入 analysis_results
// ============================================================

import { createClient } from 'npm:@supabase/supabase-js@2';

import { callDeepSeek, parseJsonResponse } from '../_shared/deepseek.ts';
import { checkGuardrails, sanitizeOutput } from '../_shared/guardrails.ts';
import { dailySystemPrompt, dailyUserPrompt } from '../_shared/prompts.ts';
import type {
  DailyAnalysisOutput,
  DailyAnalysisResult,
  DbEvent,
} from '../_shared/types.ts';

// Supabase 客户端（Service Role — 有权限读取所有用户数据）
function getSupabaseClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  return createClient(supabaseUrl, supabaseKey);
}

// CORS 头
const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

Deno.serve(async (req) => {
  // CORS preflight
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = getSupabaseClient();
    const today = new Date().toISOString().slice(0, 10); // '2026-06-04'

    // ── 1. 获取所有活动的用户 ──
    // （这里简化处理：从 events 表中获取当天有数据的所有 user_id）
    // 实际生产中可以维护一张 active_users 表
    const { data: activeUsers, error: userError } = await supabase
      .from('events')
      .select('user_id')
      .gte('timestamp', `${today}T00:00:00Z`)
      .lt('timestamp', `${today}T23:59:59Z`)
      .not('user_id', 'is', null);

    if (userError) {
      throw new Error(`查询活跃用户失败: ${userError.message}`);
    }

    const userIds = [...new Set((activeUsers || []).map((u) => u.user_id))];

    if (userIds.length === 0) {
      console.log(`[${today}] 无活跃用户，跳过`);
      return new Response(
        JSON.stringify({ message: '无活跃用户', processed: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    console.log(`[${today}] 发现 ${userIds.length} 个活跃用户`);

    // ── 2. 对每个用户执行日分析 ──
    let processedCount = 0;

    for (const userId of userIds) {
      try {
        await processUserDaily(supabase, userId, today);
        processedCount++;
        console.log(`[${today}] 用户 ${userId} 分析完成`);
      } catch (err) {
        console.error(`[${today}] 用户 ${userId} 分析失败:`, err);
        // 单个用户失败不影响其他用户
      }
    }

    return new Response(
      JSON.stringify({
        message: `日分析完成`,
        date: today,
        total: userIds.length,
        processed: processedCount,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('日分析全局错误:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : '未知错误' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

/**
 * 处理单个用户的日分析
 */
async function processUserDaily(
  supabase: ReturnType<typeof getSupabaseClient>,
  userId: string,
  date: string,
): Promise<void> {
  // ── 2a. 获取今天的事件 ──
  const { data: events, error: eventsError } = await supabase
    .from('events')
    .select('*')
    .eq('user_id', userId)
    .gte('timestamp', `${date}T00:00:00Z`)
    .lt('timestamp', `${date}T23:59:59Z`)
    .order('timestamp', { ascending: true });

  if (eventsError) {
    throw new Error(`查询事件失败: ${eventsError.message}`);
  }

  // ── 2b. 获取昨天的分析摘要（用于对比） ──
  const yesterday = new Date();
  yesterday.setDate(yesterday.getDate() - 1);
  const yesterdayStr = yesterday.toISOString().slice(0, 10);

  const { data: yesterdayAnalysis } = await supabase
    .from('analysis_results')
    .select('summary')
    .eq('user_id', userId)
    .eq('analysis_type', 'daily')
    .eq('period_start', yesterdayStr)
    .single();

  const yesterdaySummary = yesterdayAnalysis
    ? (yesterdayAnalysis.summary as unknown as DailyAnalysisOutput)?.summary || null
    : null;

  // ── 2c. 调用 DeepSeek ──
  const eventsJson = JSON.stringify(
    (events || []).map((e: DbEvent) => ({
      time: e.timestamp.slice(11, 19),
      type: e.type,
      severity: e.severity,
      freezeIndex: e.freeze_index,
      tremorFreq: e.tremor_frequency,
    })),
  );

  const response = await callDeepSeek({
    messages: [
      { role: 'system', content: dailySystemPrompt() },
      { role: 'user', content: dailyUserPrompt({
        date,
        eventsJson,
        yesterdaySummary,
      })},
    ],
    temperature: 0.3,    // 低温度保证一致性
    max_tokens: 1024,
    response_format: { type: 'json_object' },
  });

  const rawContent = response.choices[0]?.message?.content || '{}';

  // ── 2d. 护栏检查 ──
  const guardrailResult = checkGuardrails(rawContent);
  if (!guardrailResult.passed) {
    console.warn(`[${date}] 用户 ${userId} 护栏违规:`, guardrailResult.violations);
    // 违规不阻断，但记录日志
  }
  const sanitized = sanitizeOutput(rawContent);

  // ── 2e. 解析 JSON ──
  const parsed = parseJsonResponse<DailyAnalysisOutput>(sanitized);
  if (!parsed) {
    throw new Error(`LLM 返回无法解析的 JSON: ${rawContent.slice(0, 200)}`);
  }

  // ── 2f. 写入数据库 ──
  const result: DailyAnalysisResult = {
    summary: parsed,
    raw_response: rawContent,
    model_used: 'deepseek-v4-pro',
    token_usage: {
      input: response.usage?.prompt_tokens || 0,
      output: response.usage?.completion_tokens || 0,
    },
  };

  const { error: upsertError } = await supabase
    .from('analysis_results')
    .upsert({
      user_id: userId,
      analysis_type: 'daily',
      period_start: date,
      period_end: date,
      summary: result.summary as unknown as Record<string, unknown>,
      raw_response: rawContent,
      model_used: result.model_used,
      token_usage: result.token_usage,
    }, {
      onConflict: 'user_id, analysis_type, period_start',
    });

  if (upsertError) {
    throw new Error(`写入分析结果失败: ${upsertError.message}`);
  }

  // ── 2g. 如果需要告警，写入 alert_flags 和 notifications ──
  if (parsed.alertType && parsed.alertType !== 'none' && parsed.alertMessage) {
    const { error: alertError } = await supabase
      .from('alert_flags')
      .insert({
        user_id: userId,
        alert_type: parsed.alertType === 'critical' ? 'fog_spike' : 'severity_worsening',
        severity: parsed.alertType,
        title: getAlertTitle(parsed.alertType),
        body: parsed.alertMessage,
      });

    if (alertError) {
      console.error(`[${date}] 用户 ${userId} 写入告警失败:`, alertError);
    }
  }
}

function getAlertTitle(severity: string): string {
  switch (severity) {
    case 'warning': return '今日需要关注';
    case 'critical': return '⚠️ 今日需重点关注';
    default: return '今日提示';
  }
}

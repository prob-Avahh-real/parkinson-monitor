// ============================================================
// weekly-analysis — 每周分析 Edge Function
// 定时：每周日 21:00（由 pg_cron 触发）
// 功能：拉取过去 7 天的日分析 → 调用 DeepSeek → 写入 analysis_results
//       → 如果有告警 flag → 写入 notifications → 微信小程序可读
// ============================================================

import { createClient } from 'npm:@supabase/supabase-js@2';

import { callDeepSeek, parseJsonResponse } from '../_shared/deepseek.ts';
import { checkGuardrails, sanitizeOutput } from '../_shared/guardrails.ts';
import { weeklySystemPrompt, weeklyUserPrompt } from '../_shared/prompts.ts';
import type {
  DbEvent,
  DbSession,
  WeeklyAnalysisOutput,
} from '../_shared/types.ts';

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
};

function getSupabaseClient() {
  const supabaseUrl = Deno.env.get('SUPABASE_URL')!;
  const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!;
  return createClient(supabaseUrl, supabaseKey);
}

Deno.serve(async (req) => {
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders });
  }

  try {
    const supabase = getSupabaseClient();

    // 计算过去 7 天的日期范围
    const today = new Date();
    const endDate = today.toISOString().slice(0, 10);
    const startDate = new Date(today.getTime() - 7 * 86400000).toISOString().slice(0, 10);

    // ── 1. 获取这 7 天内有数据的用户 ──
    const { data: activeUsers, error: userError } = await supabase
      .from('events')
      .select('user_id')
      .gte('timestamp', `${startDate}T00:00:00Z`)
      .lt('timestamp', `${endDate}T23:59:59Z`)
      .not('user_id', 'is', null);

    if (userError) {
      throw new Error(`查询活跃用户失败: ${userError.message}`);
    }

    const userIds = [...new Set((activeUsers || []).map((u) => u.user_id))];

    if (userIds.length === 0) {
      return new Response(
        JSON.stringify({ message: '无活跃用户', processed: 0 }),
        { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
      );
    }

    // ── 2. 对每个用户执行周分析 ──
    let processedCount = 0;

    for (const userId of userIds) {
      try {
        await processUserWeekly(supabase, userId, startDate, endDate);
        processedCount++;
      } catch (err) {
        console.error(`用户 ${userId} 周分析失败:`, err);
      }
    }

    return new Response(
      JSON.stringify({
        message: '周分析完成',
        period: `${startDate} ~ ${endDate}`,
        total: userIds.length,
        processed: processedCount,
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  } catch (err) {
    console.error('周分析全局错误:', err);
    return new Response(
      JSON.stringify({ error: err instanceof Error ? err.message : '未知错误' }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } },
    );
  }
});

async function processUserWeekly(
  supabase: ReturnType<typeof getSupabaseClient>,
  userId: string,
  startDate: string,
  endDate: string,
): Promise<void> {
  // ── 2a. 获取每日分析摘要 ──
  const { data: dailyReports } = await supabase
    .from('analysis_results')
    .select('summary, period_start')
    .eq('user_id', userId)
    .eq('analysis_type', 'daily')
    .gte('period_start', startDate)
    .lte('period_start', endDate)
    .order('period_start', { ascending: true });

  const dailySummaries = (dailyReports || [])
    .map((r) => `[${r.period_start}] ${JSON.stringify(r.summary)}`)
    .join('\n');

  // ── 2b. 获取原始事件数据 ──
  const { data: rawEvents } = await supabase
    .from('events')
    .select('*')
    .eq('user_id', userId)
    .gte('timestamp', `${startDate}T00:00:00Z`)
    .lt('timestamp', `${endDate}T23:59:59Z`)
    .order('timestamp', { ascending: true });

  // ── 2c. 获取会话数据 ──
  const { data: sessions } = await supabase
    .from('sessions')
    .select('*')
    .eq('user_id', userId)
    .gte('start_time', `${startDate}T00:00:00Z`)
    .lt('start_time', `${endDate}T23:59:59Z`);

  const totalEvents = (rawEvents || []).length;
  const totalSessions = (sessions || []).length;

  // ── 2d. 调用 DeepSeek ──
  const response = await callDeepSeek({
    messages: [
      { role: 'system', content: weeklySystemPrompt() },
      { role: 'user', content: weeklyUserPrompt({
        startDate,
        endDate,
        dailySummaries: dailySummaries || '（无每日摘要）',
        totalEvents,
        totalSessions,
      })},
    ],
    temperature: 0.3,
    max_tokens: 2048,
    response_format: { type: 'json_object' },
  });

  const rawContent = response.choices[0]?.message?.content || '{}';

  // ── 2e. 护栏检查 + 解析 ──
  const guardrailResult = checkGuardrails(rawContent);
  if (!guardrailResult.passed) {
    console.warn(`用户 ${userId} 周分析护栏违规:`, guardrailResult.violations);
  }
  const sanitized = sanitizeOutput(rawContent);

  const parsed = parseJsonResponse<WeeklyAnalysisOutput>(sanitized);
  if (!parsed) {
    throw new Error(`LLM 返回无法解析的 JSON: ${rawContent.slice(0, 200)}`);
  }

  // ── 2f. 写入 analysis_results ──
  const { error: upsertError } = await supabase
    .from('analysis_results')
    .upsert({
      user_id: userId,
      analysis_type: 'weekly',
      period_start: startDate,
      period_end: endDate,
      summary: parsed as unknown as Record<string, unknown>,
      raw_response: rawContent,
      model_used: 'deepseek-v4-pro',
      token_usage: {
        input: response.usage?.prompt_tokens || 0,
        output: response.usage?.completion_tokens || 0,
      },
    }, {
      onConflict: 'user_id, analysis_type, period_start',
    });

  if (upsertError) {
    throw new Error(`写入周分析失败: ${upsertError.message}`);
  }

  // ── 2g. 写入 alert_flags ──
  if (parsed.alertFlags && parsed.alertFlags.length > 0) {
    for (const flag of parsed.alertFlags) {
      // 先插入 alert_flags
      const { data: alertInsert, error: alertError } = await supabase
        .from('alert_flags')
        .insert({
          user_id: userId,
          alert_type: flag.type,
          severity: flag.severity,
          title: flag.title,
          body: flag.body,
        })
        .select('id')
        .single();

      if (alertError) {
        console.error(`写入告警失败:`, alertError);
        continue;
      }

      // ── 2h. 写入 notifications（微信小程序读取） ──
      const { error: notifError } = await supabase
        .from('notifications')
        .insert({
          user_id: userId,
          alert_id: alertInsert.id,
          channel: 'in_app',
          title: `📊 周报: ${flag.title}`,
          body: flag.body,
          severity: flag.severity,
        });

      if (notifError) {
        console.error(`写入通知失败:`, notifError);
      }
    }
  } else {
    // 没有告警也写一条"一切正常"通知
    const { error: notifError } = await supabase
      .from('notifications')
      .insert({
        user_id: userId,
        channel: 'in_app',
        title: '📊 本周情况稳定',
        body: parsed.summaryForFamily || parsed.trendDescription || '本周未发现明显异常。',
        severity: 'info',
      });

    if (notifError) {
      console.error(`写入正常通知失败:`, notifError);
    }
  }
}

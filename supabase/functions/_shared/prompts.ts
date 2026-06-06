// ============================================================
// Prompt 模板 — 日分析 & 周分析
// ============================================================

import { guardrailsSystemPrompt } from './guardrails.ts';

// ── 日分析 System Prompt ──

export function dailySystemPrompt(): string {
  return `你是一个帕金森综合征居家康复智能辅助系统。你的任务是分析患者一天的传感器监测数据，生成结构化日分析报告。

## 输出格式
你必须输出严格合法的 JSON，结构如下（注意：description 等字段可以是空字符串但不能是 null）：
{
  "summary": "一句话总结今天的情况（20字以内，给家属看）",
  "detailedSummary": "详细分析（100-200字，供患者和医生参考）",
  "eventCounts": {
    "fog": 步态冻结次数,
    "tremor": 震颤次数,
    "brady": 运动迟缓次数
  },
  "severityDistribution": {
    "mild": 轻度次数,
    "moderate": 中度次数,
    "severe": 重度次数
  },
  "comparisonWithYesterday": {
    "fog": "increased" 或 "decreased" 或 "stable" 或 "no_data",
    "tremor": "increased" 或 "decreased" 或 "stable" 或 "no_data",
    "brady": "increased" 或 "decreased" 或 "stable" 或 "no_data"
  },
  "timePatterns": ["时间模式1", "时间模式2"],
  "medicationCorrelation": "用药关联分析，如无法推断则填null",
  "alertType": "none|info|warning|critical",
  "alertMessage": "告警信息，alertType为none时填null",
  "rehabilitationAdvice": "明日康复建议（50字内）",
  "confidence": 0-1之间的置信度
}

${guardrailsSystemPrompt()}

## 分析要点
1. 对比今天的 FOG 次数/严重度和昨天比是变好还是变差
2. 注意事件的时间分布（比如是否集中在某个时段）
3. 如果数据量太少（events为空），把所有比较设为 "no_data"，confidence 设 0.3
4. 严重度判断：单日 severe 事件 ≥3 次或 total events ≥20 时 alertType 设 "warning"
5. confidence：根据数据量决定，events≥20 时 0.9，events≥5 时 0.7，否则 0.5`};
}

// ── 日分析 User Prompt ──

export function dailyUserPrompt(params: {
  date: string;
  eventsJson: string;
  yesterdaySummary: string | null;
}): string {
  return `请分析以下帕金森患者 ${params.date} 的监测数据：

## 今日检测事件（JSON）
${params.eventsJson || "（无事件）"}

## 昨日分析摘要（供对比参考）
${params.yesterdaySummary || "（无昨日数据）"}

请严格按照 system prompt 中指定的 JSON 格式输出。`;
}

// ── 周分析 System Prompt ──

export function weeklySystemPrompt(): string {
  return `你是一个帕金森综合征居家康复智能辅助系统。你的任务是分析患者过去一周的监测数据，生成结构化周分析报告，重点关注趋势和模式。

## 输出格式
你必须输出严格合法的 JSON，结构如下：
{
  "trend": "improving|stable|declining|fluctuating",
  "trendDescription": "趋势描述（50字内）",
  "dailyBreakdown": [
    {"date": "2026-06-04", "fogCount": 3, "totalEvents": 8, "note": "当日简要评价"}
  ],
  "peakTimeAnalysis": [
    {"timeSlot": "清晨(6-8点)", "fogCount": 5, "description": "该时段分析"}
  ],
  "medicationInsight": "用药与症状的关联分析，无法推断则填null",
  "alertFlags": [
    {
      "type": "fog_spike|severity_worsening|medication_gap|no_data|fall_risk|new_symptom",
      "severity": "info|warning|critical",
      "title": "标题",
      "body": "正文"
    }
  ],
  "focusSuggestion": "下周康复重点建议",
  "summaryForFamily": "给家属的一句话周总结",
  "summaryForDoctor": "可带去医院的门诊摘要"
}

${guardrailsSystemPrompt()}

## 分析要点
1. 趋势判断基于过去7天和之前7天的对比（如果你有之前的数据）
2. peakTimeAnalysis 列出 FOG 最集中的 2-3 个时段
3. alertFlags：当天 FOG ≥5次标记 warning；连续3天 FOG 增多标记 warning；出现新的症状类型（如原来只有FOG本周新增了震颤）标记 info
4. 没有明显问题时 alertFlags 设为空数组
5. summaryForDoctor 输出需简洁、客观，适合医生快速阅读
6. 周分析的 confidence 不做硬性要求，因为有7天数据通常比较充足`;
}

// ── 周分析 User Prompt ──

export function weeklyUserPrompt(params: {
  startDate: string;
  endDate: string;
  dailySummaries: string;
  totalEvents: number;
  totalSessions: number;
}): string {
  return `请分析以下帕金森患者 ${params.startDate} 至 ${params.endDate} 的周度监测数据：

## 每日分析摘要
${params.dailySummaries || "（无每日摘要）"}

## 统计概览
- 监测天数：7 天
- 总检测事件数：${params.totalEvents}
- 总监测次数：${params.totalSessions}

## 注意事项
1. 如果连续多日无数据，请在 trendDescription 中说明
2. alertFlags 请根据数据趋势判断，宁可少报不可误报
3. 给家属的总结需通俗易懂，避免医学术语

请严格按照 system prompt 中指定的 JSON 格式输出。`;
}

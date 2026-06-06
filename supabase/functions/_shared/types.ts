// ============================================================
// 共享类型定义
// ============================================================

// ── 检测事件类型（对应 Flutter MovementDisorderType 枚举） ──
export const MOVEMENT_TYPE = {
  FREEZING_OF_GAIT: 0,
  RESTING_TREMOR: 1,
  BRADYKINESIA: 2,
  POSTURAL_INSTABILITY: 3,
  NORMAL: 4,
} as const;

// ── 严重程度（对应 Flutter Severity 枚举） ──
export const SEVERITY = {
  MILD: 0,
  MODERATE: 1,
  SEVERE: 2,
} as const;

// ── 数据库事件行 ──
export interface DbEvent {
  id: string;
  session_id: string;
  user_id: string;
  timestamp: string;
  type: number;          // 0-4
  severity: number;      // 0-2
  confidence: number;
  freeze_index: number | null;
  tremor_frequency: number | null;
  movement_amplitude: number | null;
}

// ── 数据库会话行 ──
export interface DbSession {
  id: string;
  user_id: string;
  start_time: string;
  end_time: string | null;
  mode: number;
  events: DbEvent[];
  total_distance_meters: number;
  total_steps: number;
}

// ── 日分析输入 ──
export interface DailyAnalysisInput {
  userId: string;
  date: string;           // '2026-06-04'
  events: DbEvent[];
  yesterdaySummary: string | null;  // 昨天的分析总结，用来做对比
}

// ── 日分析输出（LLM 生成的 JSON 结构） ──
export interface DailyAnalysisOutput {
  summary: string;            // 一句话总结（给家属看）
  detailedSummary: string;    // 详细版（给患者/医生看）
  eventCounts: {
    fog: number;
    tremor: number;
    brady: number;
  };
  severityDistribution: {
    mild: number;
    moderate: number;
    severe: number;
  };
  comparisonWithYesterday: {
    fog: 'increased' | 'decreased' | 'stable' | 'no_data';
    tremor: 'increased' | 'decreased' | 'stable' | 'no_data';
    brady: 'increased' | 'decreased' | 'stable' | 'no_data';
  };
  timePatterns: string[];     // ["午后(13-15点)FOG高发", "早上运动迟缓较明显"]
  medicationCorrelation: string | null;  // 如能推断用药关联则写，否则 null
  alertType: 'none' | 'info' | 'warning' | 'critical';
  alertMessage: string | null;
  rehabilitationAdvice: string;  // 康复建议
  confidence: number;             // 0-1
}

// ── 日分析结果写入数据库的格式 ──
export interface DailyAnalysisResult {
  summary: DailyAnalysisOutput;
  raw_response: string;
  model_used: string;
  token_usage: { input: number; output: number };
}

// ── 周分析输入 ──
export interface WeeklyAnalysisInput {
  userId: string;
  startDate: string;      // '2026-05-29'（7天前）
  endDate: string;        // '2026-06-04'（今天）
  dailyReports: string[];  // 7天的日分析总结
  rawEvents: DbEvent[];
  sessions: DbSession[];
}

// ── 周分析输出 ──
export interface WeeklyAnalysisOutput {
  trend: 'improving' | 'stable' | 'declining' | 'fluctuating';
  trendDescription: string;            // "本周步态稳定性较上周改善约15%"
  dailyBreakdown: {
    date: string;
    fogCount: number;
    totalEvents: number;
    note: string;
  }[];
  peakTimeAnalysis: {
    timeSlot: string;                  // "清晨(6-8点)"
    fogCount: number;
    description: string;
  }[];
  medicationInsight: string | null;
  alertFlags: {
    type: string;
    severity: 'info' | 'warning' | 'critical';
    title: string;
    body: string;
  }[];
  focusSuggestion: string;             // "下周建议加强转身训练"
  summaryForFamily: string;            // 一句话总结发给家属
  summaryForDoctor: string;            // 可带去门诊的摘要
}

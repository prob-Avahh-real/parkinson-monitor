-- ============================================================
-- Migration 004: Agent 分析层 — 日分析/周分析/通知表
-- 依赖: 已有 events, sessions 表（migration 003）
-- ============================================================

-- ----------------------------------------
-- 1. 分析结果表
-- ----------------------------------------
CREATE TABLE analysis_results (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  analysis_type TEXT NOT NULL CHECK (analysis_type IN ('daily', 'weekly')),
  period_start DATE NOT NULL,
  period_end DATE NOT NULL,
  summary JSONB NOT NULL,
  raw_response TEXT,
  model_used TEXT DEFAULT 'deepseek-v4-pro',
  token_usage JSONB DEFAULT '{"input": 0, "output": 0}',
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW(),
  -- 每个用户每天/每周只有一条
  UNIQUE(user_id, analysis_type, period_start)
);

-- 查询加速
CREATE INDEX idx_analysis_user_period ON analysis_results(user_id, analysis_type, period_start DESC);
CREATE INDEX idx_analysis_created ON analysis_results(created_at DESC);

-- ----------------------------------------
-- 2. 警告/异常标记表
-- ----------------------------------------
CREATE TABLE alert_flags (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  analysis_id UUID REFERENCES analysis_results(id) ON DELETE CASCADE,
  alert_type TEXT NOT NULL CHECK (alert_type IN (
    'fog_spike',           -- FOG 突然增多
    'severity_worsening',  -- 严重度整体恶化
    'medication_gap',      -- 用药与症状关联异常
    'no_data',             -- 连续多日无数据
    'fall_risk',           -- 跌倒风险升高
    'new_symptom'          -- 出现新的症状类型
  )),
  severity TEXT NOT NULL CHECK (severity IN ('info', 'warning', 'critical')),
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  dismissed BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_alerts_user ON alert_flags(user_id, created_at DESC);
CREATE INDEX idx_alerts_undismissed ON alert_flags(user_id, dismissed, severity);

-- ----------------------------------------
-- 3. 通知表（供微信小程序读取）
-- ----------------------------------------
CREATE TABLE notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users NOT NULL,
  alert_id UUID REFERENCES alert_flags(id) ON DELETE SET NULL,
  channel TEXT NOT NULL DEFAULT 'in_app',
  title TEXT NOT NULL,
  body TEXT NOT NULL,
  severity TEXT NOT NULL DEFAULT 'info' CHECK (severity IN ('info', 'warning', 'critical')),
  read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_notifications_user ON notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON notifications(user_id, read, created_at DESC);

-- ----------------------------------------
-- 4. DeepSeek API 配置表（可选）
-- ----------------------------------------
CREATE TABLE IF NOT EXISTS secrets (
  key TEXT PRIMARY KEY,
  value TEXT NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ----------------------------------------
-- 5. Row Level Security
-- ----------------------------------------
ALTER TABLE analysis_results ENABLE ROW LEVEL SECURITY;
ALTER TABLE alert_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

CREATE POLICY "用户拥有自己的分析结果" ON analysis_results
  USING (auth.uid() = user_id);

CREATE POLICY "用户拥有自己的警告" ON alert_flags
  USING (auth.uid() = user_id);

CREATE POLICY "用户拥有自己的通知" ON notifications
  USING (auth.uid() = user_id);

-- ----------------------------------------
-- 6. 自动更新 updated_at
-- ----------------------------------------
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_analysis_results_updated_at
  BEFORE UPDATE ON analysis_results
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ----------------------------------------
-- 7. 定时任务调度（依赖 pg_cron 扩展）
-- ----------------------------------------
-- 此部分在 Supabase 控制台中通过 SQL 编辑器手动执行
-- 或在 supabase/config.toml 中配置

-- 日分析：每天 21:00 运行
-- SELECT cron.schedule(
--   'daily-analysis',
--   '0 21 * * *',
--   $$SELECT net.http_post(
--     url := 'https://YOUR_PROJECT.supabase.co/functions/v1/daily-analysis',
--     headers := jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
--     ),
--     body := '{}'
--   )$$
-- );

-- 周分析：每周日 21:00 运行
-- SELECT cron.schedule(
--   'weekly-analysis',
--   '0 21 * * 0',
--   $$SELECT net.http_post(
--     url := 'https://YOUR_PROJECT.supabase.co/functions/v1/weekly-analysis',
--     headers := jsonb_build_object(
--       'Content-Type', 'application/json',
--       'Authorization', 'Bearer YOUR_SERVICE_ROLE_KEY'
--     ),
--     body := '{}'
--   )$$
-- );

-- 查看已有定时任务
-- SELECT * FROM cron.job;

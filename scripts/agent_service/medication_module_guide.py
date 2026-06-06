"""用药记录模块 — Flutter App 端需要新增的文件说明 + Supabase表结构"""

# ════════════════════════════════════════════════
# Flutter App 新增：用药记录模块
# ════════════════════════════════════════════════
#
# 新增文件（3个）：
#   lib/domain/entities/medication_record.dart
#   lib/services/medication_service.dart
#   lib/presentation/pages/medication_page.dart
#
# 修改文件（2个）：
#   lib/core/di/injection_container.dart  (+ 注册新 service)
#   lib/presentation/pages/home_page.dart  (+ 入口按钮)
#
# 不需要修改 Supabase 表结构
#   直接用 agent_service 里的主入口创建表
#
# ════════════════════════════════════════════════

"""
-- Supabase 用药记录表（通过 Agent 服务的 SQL 脚本创建）

CREATE TABLE IF NOT EXISTS medication_records (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users NOT NULL,
  recorded_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  medication_name TEXT NOT NULL DEFAULT '左旋多巴',
  dosage_mg FLOAT,
  note TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_medication_user_time ON medication_records(user_id, recorded_at DESC);

ALTER TABLE medication_records ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own medication records"
  ON medication_records USING (auth.uid() = user_id);
"""

"""Agent 服务 → App 接口文档

描述 Flutter App 需要做什么调整来配合 Agent 层
"""

# ═══════════════════════════════════════════════════════
# Flutter App 配合 Agent 层的接口约定
# ═══════════════════════════════════════════════════════
#
# 前提：你的 App 已经将 events/sessions 同步到 Supabase。
# Agent 服务直接从 Supabase 读取数据，不需要改动现有架构。
#
# 以下是推荐新增的字段，用于让用药关联分析更精准：

# ── events 表新增可选字段 ─────────────────────────────

"""
ALTER TABLE events ADD COLUMN IF NOT EXISTS medication_time TIMESTAMPTZ;
  -- 最近一次用药时间
  -- 用于分析"距离用药 X 分钟后"的事件分布

ALTER TABLE events ADD COLUMN IF NOT EXISTS context_activity TEXT;
  -- 事件发生时的活动上下文
  -- 可选值: "walking", "turning", "standing", "sitting", "doorway"
  -- 用于分析"什么场景容易触发 FOG"
"""

# ── App 端采集建议 ────────────────────────────────────
#
# 1. 用药提醒模块（最值得加）
#    患者或家属在 App 里记录用药时间
#    Agent 自动关联"用药后 X 分钟"与"事件频率"的关系
#    实现方式：一个简单的"记录用药时间"按钮 + 推送提醒
#
# 2. 事件上下文
#    检测到 FOG 时，记录当前活动（行走/转弯/站立）
#    可通过 IMU 信号简单分类，不需要额外传感器
#
# 3. 以上两项都是可选的
#    没有这些字段，Agent 仍然可以工作
#    只是用药关联分析变成"按时间段观察"而非"按用药时间观察"

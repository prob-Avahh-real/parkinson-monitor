# 产品后端 — Supabase 配置与截图

## 后端架构

Supabase (GMI Cloud Hosted) → Auth (匿名) + Database (sessions/events) + RLS Policies

## 初始化 SQL

在 Supabase SQL Editor 执行:

```sql
CREATE TABLE sessions (
  id TEXT PRIMARY KEY, user_id UUID REFERENCES auth.users NOT NULL,
  start_time TIMESTAMPTZ NOT NULL DEFAULT NOW(), end_time TIMESTAMPTZ,
  mode INTEGER NOT NULL DEFAULT 0, events JSONB DEFAULT '[]',
  total_distance_meters FLOAT DEFAULT 0, total_steps INTEGER DEFAULT 0,
  gps_path JSONB DEFAULT '[]', created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE events (
  id TEXT PRIMARY KEY, session_id TEXT REFERENCES sessions(id) ON DELETE CASCADE NOT NULL,
  user_id UUID REFERENCES auth.users NOT NULL, timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  type INTEGER NOT NULL, severity INTEGER NOT NULL DEFAULT 0,
  confidence FLOAT DEFAULT 0, freeze_index FLOAT,
  tremor_frequency FLOAT, movement_amplitude FLOAT
);

CREATE INDEX idx_sessions_user ON sessions(user_id, start_time DESC);
CREATE INDEX idx_events_user ON events(user_id, timestamp DESC);

ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own data" ON sessions USING (auth.uid() = user_id);
CREATE POLICY "Users own events" ON events USING (auth.uid() = user_id);
```

## 后端截图 1: 数据库表 → `screenshots/backend_01_tables.png` (1920×1080)
Supabase Dashboard → Table Editor → sessions 和 events 表结构

## 后端截图 2: RLS 策略 → `screenshots/backend_02_rls.png` (1920×1080)
Authentication → Policies → 显示已启用的策略列表

## 后端截图 3: SQL 查询 → `screenshots/backend_03_query.png` (1920×1080)
SQL Editor 中执行查询并显示结果表格

## 后端截图 4: API 文档 → `screenshots/backend_04_api.png` (1920×1080)
API Docs → GET/POST /sessions 和 /events 端点展示

## 注意
截图前打码 project ID 和 API key

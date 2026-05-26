#!/bin/bash
# ============================================
# Supabase 后端验证 + URL 生成
# 用法: SUPABASE_URL=xxx SUPABASE_ANON_KEY=yyy bash scripts/backend_check.sh
# ============================================
set -e

SUPABASE_URL="${SUPABASE_URL:-}"
SUPABASE_ANON_KEY="${SUPABASE_ANON_KEY:-}"

if [ -z "$SUPABASE_URL" ]; then
  echo "⚠️  请设置环境变量:"
  echo "  export SUPABASE_URL=https://YOUR_PROJECT.supabase.co"
  echo "  export SUPABASE_ANON_KEY=YOUR_ANON_KEY"
  echo ""
  echo "然后手动截图 Supabase Dashboard:"
  echo ""
  echo "  backend_01_tables.png ← Table Editor"
  echo "    打开: $SUPABASE_URL/project/default/editor"
  echo ""
  echo "  backend_02_rls.png ← Authentication → Policies"
  echo "    打开: $SUPABASE_URL/project/default/auth/policies"
  echo ""
  echo "  backend_03_query.png ← SQL Editor"
  echo "    打开: $SUPABASE_URL/project/default/sql/new"
  echo "    执行: SELECT COUNT(*), DATE(start_time) ..."
  echo ""
  echo "  backend_04_api.png ← API Docs"
  echo "    打开: $SUPABASE_URL/project/default/api"
  echo ""
  exit 0
fi

echo "☁️  验证 Supabase 连接..."
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
  -H "apikey: $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/rest/v1/" 2>/dev/null || echo "000")

if [ "$HTTP_CODE" = "200" ]; then
  echo "  ✓ Supabase 连接正常 (HTTP $HTTP_CODE)"
else
  echo "  ⚠️  Supabase 返回 HTTP $HTTP_CODE"
fi

echo ""
echo "📊 查询统计..."
SESSIONS=$(curl -s -H "apikey: $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/rest/v1/sessions?select=count" 2>/dev/null | grep -o '[0-9]*' || echo "N/A")
EVENTS=$(curl -s -H "apikey: $SUPABASE_ANON_KEY" \
  "$SUPABASE_URL/rest/v1/events?select=count" 2>/dev/null | grep -o '[0-9]*' || echo "N/A")

echo "  sessions: $SESSIONS"
echo "  events:   $EVENTS"

echo ""
echo "📸 截图指引 (在浏览器打开):"
echo "  Table Editor:  $SUPABASE_URL/project/default/editor"
echo "  Policies:      $SUPABASE_URL/project/default/auth/policies"
echo "  SQL Editor:    $SUPABASE_URL/project/default/sql/new"
echo "  API Docs:      $SUPABASE_URL/project/default/api"

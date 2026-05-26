#!/bin/bash
# ============================================
# Parkinson Monitor — 自动截图 + 录屏脚本
# ============================================
set -e

PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUTPUT_DIR="$PROJECT_DIR/deliverables/screenshots"
FLUTTER="$HOME/flutter-sdk/bin/flutter"

mkdir -p "$OUTPUT_DIR"

echo "🔍 检查模拟器..."
BOOTED=$(xcrun simctl list devices booted | grep -c "Booted" || true)
if [ "$BOOTED" -eq 0 ]; then
  echo "⚠️  没有启动的模拟器，尝试启动 iPhone 16..."
  UDID=$(xcrun simctl list devices available iPhone | grep -m1 "iPhone 16" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
  if [ -z "$UDID" ]; then
    UDID=$(xcrun simctl list devices available iPhone | grep -m1 "iPhone" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
  fi
  xcrun simctl boot "$UDID" 2>/dev/null || true
  open -a Simulator
  sleep 15
fi

echo "📱 启动 App..."
cd "$PROJECT_DIR"
$FLUTTER run --debug 2>&1 &
APP_PID=$!
sleep 30  # 等待 App 启动

# 截图函数: iOS 模拟器截图
capture() {
  local name="$1"
  sleep 2
  xcrun simctl io booted screenshot "$OUTPUT_DIR/${name}.png" 2>/dev/null || \
  xcrun simctl io booted screenshot "$OUTPUT_DIR/${name}.png"
  echo "  ✓ $name.png"
}

echo ""
echo "📸 开始截图..."
echo ""

# 1. 首页
echo "1/5 首页仪表盘"
capture "01_home"

# 2. 设备扫描页 — 需要手动点击 (无法脚本化点按)
echo "2/5 设备扫描页 (请手动点击首页的 '设备管理' 按钮)"
echo "   等待 5 秒..."
sleep 5
capture "02_device_scan"

# 3. 设置页
echo "3/5 设置页 (请手动点击设置图标)"
echo "   等待 5 秒..."
sleep 5
capture "03_calibration"

# 4. 监测页
echo "4/5 监测页 (请手动返回首页 → 选择模式 → 开始监测)"
echo "   等待 5 秒..."
sleep 5
capture "04_monitoring"

# 5. 历史页
echo "5/5 历史页 (请手动点击历史记录)"
echo "   等待 5 秒..."
sleep 5
capture "05_history"

# 6. 录屏
echo ""
echo "🎬 开始录屏 (3 分钟)..."
xcrun simctl io booted recordVideo "$OUTPUT_DIR/demo.mp4" &
RECORD_PID=$!

echo "   录屏中... 3 分钟倒计时"
sleep 180
kill "$RECORD_PID" 2>/dev/null || true
echo "  ✓ demo.mp4"

# 7. Supabase 后端截图 (用 curl 验证 + 手动)
echo ""
echo "☁️  Supabase 后端截图..."
SUPABASE_URL="${SUPABASE_URL:-}"  # 从环境变量读取
if [ -n "$SUPABASE_URL" ]; then
  echo "  验证 Supabase 连接..."
  curl -s "$SUPABASE_URL/rest/v1/" -H "apikey: ${SUPABASE_ANON_KEY:-}" | head -c 100 || echo "  ⚠️  Supabase 未配置，跳过"
else
  echo "  ⚠️  未设置 SUPABASE_URL 环境变量，跳过后端截图"
  echo "  请手动截图 Supabase Dashboard:"
  echo "    - Table Editor → backend_01_tables.png"
  echo "    - Auth → Policies → backend_02_rls.png"
  echo "    - SQL Editor → backend_03_query.png"
  echo "    - API Docs → backend_04_api.png"
fi

# 清理
kill "$APP_PID" 2>/dev/null || true

echo ""
echo "✅ 完成!"
echo "截图: $OUTPUT_DIR/"
ls -la "$OUTPUT_DIR/"*.png 2>/dev/null || echo "  (截图文件待查看)"
ls -la "$OUTPUT_DIR/"*.mp4 2>/dev/null || echo "  (视频文件待查看)"

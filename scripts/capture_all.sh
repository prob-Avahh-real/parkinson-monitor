#!/bin/bash
# ============================================
# Parkinson Monitor — 全自动截图 + 录屏
# 用法: bash scripts/capture_all.sh
# ============================================
set -e
PROJECT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$PROJECT_DIR/deliverables/screenshots"
FLUTTER="$HOME/flutter-sdk/bin/flutter"
mkdir -p "$OUT_DIR"

# ── 1. 启动模拟器 ──
echo "🔍 启动模拟器..."
BOOTED=$(xcrun simctl list devices booted | grep -c "Booted" || true)
if [ "$BOOTED" -eq 0 ]; then
  UDID=$(xcrun simctl list devices available iPhone | grep -m1 "iPhone" | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')
  xcrun simctl boot "$UDID" 2>/dev/null || true
  open -a Simulator
  sleep 20
fi

# ── 2. 启动 App ──
echo "📱 flutter run..."
cd "$PROJECT_DIR"
$FLUTTER run -d "$(xcrun simctl list devices booted | grep Booted | head -1 | sed -E 's/.*\(([A-F0-9-]+)\).*/\1/')" &
APP_PID=$!
sleep 35

# ── 3. 录屏 (在截图前启动，覆盖全过程) ──
echo "🎬 开始录屏..."
xcrun simctl io booted recordVideo "$OUT_DIR/demo_full.mp4" &
VIDEO_PID=$!

# ── 4. 截图函数 ──
shot() { sleep 2; xcrun simctl io booted screenshot "$OUT_DIR/$1"; echo "  ✓ $1"; }

click() {
  # 模拟点击: x y 坐标 (iPhone 14 Pro Max 分辨率 430×932, 坐标归一化 0-1)
  # 需要根据实际页面布局调整坐标
  xcrun simctl ui booted tap 215 400 2>/dev/null || true
  sleep 1
}

echo ""
echo "📸 开始截图..."

# 截图 1: 首页
echo "1/5 首页"
shot "01_home.png"

# 截图 2: 设备扫描 — 点击"设备管理"按钮
echo "2/5 设备扫描"
# 设备管理按钮在功能入口网格第四格 (右下角)
xcrun simctl ui booted tap 300 730
sleep 2
shot "02_device_scan.png"

# 返回
xcrun simctl ui booted tap 50 50
sleep 1

# 截图 3: 设置 — 点击齿轮图标
echo "3/5 设置/校准"
xcrun simctl ui booted tap 400 40
sleep 2
shot "03_calibration.png"

# 返回
xcrun simctl ui booted tap 50 50
sleep 1

# 截图 4: 监测 — 点击户外模式按钮
echo "4/5 实时监测"
xcrun simctl ui booted tap 300 480
sleep 3
shot "04_monitoring.png"

# 停止监测 + 返回
xcrun simctl ui booted tap 250 800
sleep 2
xcrun simctl ui booted tap 50 50
sleep 1

# 截图 5: 历史 — 点击历史记录
echo "5/5 历史记录"
xcrun simctl ui booted tap 150 730
sleep 2
shot "05_history.png"

# ── 5. 停止录屏 ──
sleep 5
kill "$VIDEO_PID" 2>/dev/null || true
echo "  ✓ 录屏完成 → demo_full.mp4"

# 截取 3 分钟精华版 (取前 180 秒)
ffmpeg -y -i "$OUT_DIR/demo_full.mp4" -t 180 -c copy "$OUT_DIR/demo_3min.mp4" 2>/dev/null && \
  echo "  ✓ 3 分钟精华版 → demo_3min.mp4" || echo "  ⚠️ ffmpeg 不可用，保留完整版"

# ── 6. 清理 ──
kill "$APP_PID" 2>/dev/null || true

echo ""
echo "✅ 完成！"
ls -lh "$OUT_DIR/"*.png "$OUT_DIR/"*.mp4 2>/dev/null

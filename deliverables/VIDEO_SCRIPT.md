# Demo 视频分镜脚本

## 视频信息
- 时长: 3 分钟 | 分辨率: 1080×1920 (竖屏) | 帧率: 30fps | 格式: MP4 H.264

## 分镜脚本

### 镜头 1: 片头 (0:00-0:15)
App 图标居中 + "Parkinson Monitor" + 副标题 + 淡入转场
字幕: "Parkinson Monitor — 让每一步都被看见"

### 镜头 2: 设备连接 (0:15-0:40)
首页 → 设备管理 → BLE 扫描 → 发现设备 → 连接成功 → 振动反馈
字幕: "支持任何 BLE 智能手表/手环"
画中画: 手部佩戴智能手表

### 镜头 3: 传感器校准 (0:40-1:10)
设置 → 开始校准 → 进度条 0→100% → 校准完成 → 个性化阈值结果
字幕: "30 秒个性化基线校准，自适应阈值"
画中画: 用户正常行走

### 镜头 4: 实时监测 (1:10-1:50)
户外模式 → 实时波形图 → 指标面板更新 → 绿色"行走正常"
字幕: "50Hz 实时采样 · GPS 轨迹记录"
特效: 波形图平滑滚动

### 镜头 5: 异常检测 (1:50-2:10)
模拟 FoG → 红色告警横幅 → 脉冲动画 → 振动 → 事件记录
字幕: "实时步态冻结检测 — Freeze Index > 1.8"
特效: 红色告警 + 脉冲圆点

### 镜头 6: 数据回顾 (2:10-2:40)
停止监测 → 今日摘要 → 历史记录 → PDF 导出 → 分享菜单
字幕: "一键生成 PDF 医疗报告，直接分享给医生"

### 镜头 7: 片尾 (2:40-3:00)
PDF 预览 → Logo + "MIT License · 开源免费"
字幕: "Parkinson Monitor — 用技术温暖每一次行走"

## 录制方法
- macOS + iPhone: QuickTime → 文件 → 新建影片录制 → 选择 iPhone
- macOS + Android: scrcpy --record demo.mp4

## 后期处理
```bash
ffmpeg -i demo_raw.mp4 -t 00:03:00 -c copy demo_final.mp4
ffmpeg -i demo_final.mp4 -vf "subtitles=subtitles.srt" demo_subtitled.mp4
ffmpeg -i demo_subtitled.mp4 -vcodec h264 -crf 23 demo_720p.mp4
```

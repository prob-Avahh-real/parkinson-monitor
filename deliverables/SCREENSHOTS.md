# 产品截图方案

## 要求
- ≥ 5 张, ≥ 1280×720 (720P), PNG 格式

## 截图 1: 首页仪表盘 → `screenshots/01_home.png` (1080×2340)
- AppBar "Parkinson Monitor" + 设置图标
- 设备状态卡片: "设备已连接 SmartWatch-X" 绿色
- 今日摘要: 4 指标 (时长/FoG/震颤/迟缓)
- 快速开始: 室内/户外双模式
- 4 宫格功能入口

## 截图 2: 设备扫描 → `screenshots/02_device_scan.png` (1080×2340)
- "设备管理" AppBar
- BLE 扫描进度条
- 设备列表 (RSSI 排序): 名称/ID/信号/dBm/连接按钮
- 绿灯已连接区域

## 截图 3: 传感器校准 → `screenshots/03_calibration.png` (1080×2340)
- 设置页面
- 校准卡片: "已校准" + 绿色对勾 + 日期 + 重新校准按钮
- 检测参数滑块: FoG 阈值 2.1 / 采样率 50Hz
- 数据管理: 云同步 + PDF 导出

## 截图 4: 实时监测 (正常) → `screenshots/04_monitoring_normal.png` (1080×2340)
- "实时监测" AppBar + 户外图标
- 绿色横幅 "● 行走正常"
- fl_chart 波形图 (120 点滚动)
- 指标面板: 步频 92/min · FI 0.45 · 震颤 1.5Hz · 振幅 0.8g
- 红色 "停止监测" 按钮

## 截图 5: 实时监测 (告警) → `screenshots/05_monitoring_alert.png` (1080×2340)
- 红色横幅 "⚠ 步态冻结" + 脉冲动画
- 红色波形图 (高频振荡)
- 指标面板: FI 4.2 · 震颤 5.1Hz · 振幅 0.05g
- 事件列表: FoG SEVERE 84% + FoG MODERATE 72% + Tremor MILD 61%

## 截图方法
1. `flutter run` 启动应用
2. iOS 模拟器: `Cmd+S` / Android: 工具栏相机图标
3. 放到 `deliverables/screenshots/` 目录

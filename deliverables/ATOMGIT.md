# AtomGit 项目主页

## 项目地址

**AtomGit**: https://atomgit.com/parkinson-monitor/parkinson-monitor

> 注：将仓库推送至 AtomGit 后替换为实际地址。

## 项目简介 (用于 AtomGit 首页)

Parkinson Monitor 是一款面向帕金森综合征患者的开源可穿戴运动障碍监测应用。通过 BLE 连接智能手表/手环，实时采集加速度计与陀螺仪数据，基于自研 FFT 频域分析算法，自动检测步态冻结、静止性震颤和运动迟缓三类核心运动症状。

特性：
- 50Hz 实时采样，毫秒级检测响应
- 自研 Cooley-Tukey FFT 信号处理器，离线可用
- 个性化基线校准，自适应检测阈值
- 户外模式 GPS 轨迹记录
- 一键生成 PDF 医疗报告
- Supabase 云端同步 (GMI Cloud 兼容)
- 35 单元测试，零 Lint 告警

技术栈：Flutter 3.44 + Dart 3.12 + BLoC + Hive + BLE

## 体验链接

### 在线体验 (GitHub Pages)
https://YOUR_ORG.github.io/parkinson-monitor

### 本地体验
```bash
git clone https://atomgit.com/YOUR_ORG/parkinson-monitor.git
cd parkinson-monitor
flutter pub get
flutter run
```

# Parkinson Monitor

帕金森综合征运动障碍可穿戴监测应用 — 通过 BLE 可穿戴设备实时检测步态冻结、静止性震颤和运动迟缓。

## 功能

| 功能 | 描述 |
|------|------|
| **BLE 设备连接** | 扫描并连接智能手表/手环等 BLE 可穿戴设备 |
| **实时监测** | 加速度计 + 陀螺仪数据采集，50Hz 采样率 |
| **步态冻结检测** | Freeze Index (FFT 频域分析)，3-8Hz vs 0.5-3Hz 功率比 |
| **静止性震颤检测** | 4-6Hz 节律性振荡识别 |
| **运动迟缓检测** | 运动幅度 + 步频 + 手臂摆动多维度评估 |
| **GPS 轨迹记录** | 户外模式自动记录行走路径和距离 |
| **个性化校准** | 采集用户正常步态基线，计算个性化检测阈值 |
| **PDF 医疗报告** | 生成含统计图表和分析建议的专业报告 |
| **Supabase 云同步** | 可选云端数据备份与多设备同步 |

## 架构

```
lib/
├── main.dart                    # 应用入口
├── core/
│   ├── constants/               # 采样率、阈值、存储键
│   ├── theme/                   # Material 3 主题
│   ├── di/                      # GetIt 依赖注入
│   └── utils/                   # FFT 信号处理器
├── domain/
│   ├── entities/                # SensorReading, DetectionEvent, MonitoringSession
│   └── repositories/            # 仓库接口 (Clean Architecture)
├── data/
│   ├── models/                  # JSON 序列化适配器
│   └── repositories/            # 仓库实现 (BLE/Hive)
├── services/
│   ├── ble_service.dart         # Bluetooth Low Energy
│   ├── detection_engine.dart    # 核心检测算法
│   ├── location_service.dart    # GPS 轨迹
│   ├── calibration_service.dart # 阈值校准
│   ├── feedback_service.dart    # 振动/声音反馈
│   ├── supabase_sync_service.dart # 云同步
│   └── report_generator.dart    # PDF 报告
└── presentation/
    ├── blocs/                   # BLoC 状态管理
    └── pages/                   # 5 个页面 (首页/设备/监测/历史/设置)
```

## 快速开始

### 前置条件

- Flutter 3.44+ / Dart 3.12+
- iOS 14+ 或 Android 8+
- 支持 BLE 的可穿戴设备 (可选，有手机传感器回退)

### 安装

```bash
cd parkinson-monitor
flutter pub get
cp .env.example .env
# Edit .env with your configuration
flutter run
```

### 开发工具

使用 Makefile 简化开发流程：

```bash
make help              # 查看所有可用命令
make install           # 安装依赖
make test              # 运行单元测试
make analyze           # 运行静态分析
make format            # 格式化代码
make build-android     # 构建 Android APK
make build-ios         # 构建 iOS 应用
make release           # 创建发布版本
```

### 运行测试

```bash
make test
```

## 配置

### Supabase 云同步 (可选)

在 `.env` 文件中配置：

```bash
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_ANON_KEY=your-anon-key
ENABLE_CLOUD_SYNC=true
```

### 监控配置 (生产环境)

在 `.env` 文件中配置：

```bash
SENTRY_DSN=https://your-sentry-dsn@sentry.io/project-id
FIREBASE_ENABLED=true
ENABLE_CRASH_REPORTING=true
ENABLE_ANALYTICS=true
```

### 检测阈值自定义

检测阈值可通过设置页面手动调整，或使用传感器校准功能自动计算个性化阈值。

## 检测算法

### 步态冻结 (Freezing of Gait)

- **方法**: 冻结指数 FI = P(3-8Hz) / P(0.5-3Hz)
- **阈值**: FI > 1.8
- **数据源**: 垂直加速度 (accelZ)
- **参考**: Moore et al. (2008), "Automatic detection of freezing of gait"

### 静止性震颤 (Resting Tremor)

- **方法**: FFT 峰值检测 + 频带功率分析
- **频段**: 4-6 Hz (帕金森典型震颤频率)
- **数据源**: 水平加速度 (accelX)

### 运动迟缓 (Bradykinesia)

- **方法**: 多维度评估 (运动幅度 + 步频 + 手臂摆动)
- **数据源**: 加速度幅值 + 垂直加速度 + 角速度

## 部署

详细的部署指南请参考：
- [Android 部署指南](docs/deployment/android.md)
- [iOS 部署指南](docs/deployment/ios.md)

### 发布流程

```bash
# 更新版本号
# 编辑 pubspec.yaml: version: 1.0.0+1

# 创建发布标签
make release

# 这将触发 GitHub Actions 自动构建并发布
```

## 免责声明

本应用为辅助监测工具，不提供医疗诊断。检测结果仅供参考，请咨询专业医生获取准确的医疗建议。

## 许可证

MIT License

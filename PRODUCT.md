# Parkinson Monitor — 产品文档

> 帕金森综合征运动障碍可穿戴监测应用
> 版本 1.0.0 · 2026-05-25

---

## 一、亮点挖掘

### 核心卖点

- **实时性**: 50Hz 传感器采样，毫秒级检测延迟，运动障碍事件即时反馈
- **准确性**: 手写 Cooley-Tukey FFT 频域分析 + 三通道交叉验证
- **个性化**: 30 秒基线校准，均值+σ 自适应阈值，千人千面
- **全场景**: BLE 可穿戴 + 手机传感器双数据源，室内/户外双模式
- **医疗级**: PDF 报告含频域指标、事件时序、严重度分布，可直接交付医生

### 技术护城河

**自研 FFT 信号处理器** — 纯 Dart 实现 Cooley-Tukey 基数-2 FFT，支持 `totalBandPower` / `bandPower` 双模功率计算，6 秒滑动窗口。

**三维检测引擎** — 步态冻结 (Freeze Index)、静止性震颤 (4-6Hz 峰值)、运动迟缓 (幅度+步频+角速度) 三项独立检测。

**连续确认 + 防抖** — 连续 3 帧确认消除瞬时噪声，3 秒防抖避免重复告警。

### 竞品对比

| 特性 | Parkinson Monitor | Kinesia | PKG Watch | 手机 App 类 |
|------|:--:|:--:|:--:|:--:|
| BLE 可穿戴支持 | ✓ | ✓ | ✓ | ✗ |
| 手机传感器回退 | ✓ | ✗ | ✗ | ✓ |
| 自研 FFT (离线可用) | ✓ | ✗ | ✗ | ✗ |
| 个性化基线校准 | ✓ | ✗ | ✗ | ✗ |
| GPS 轨迹记录 | ✓ | ✗ | ✗ | ✗ |
| PDF 医疗报告 | ✓ | ✓ | ✓ | ✗ |
| 开源 / MIT 协议 | ✓ | ✗ | ✗ | 部分 |

---

## 二、团队介绍

### 团队架构

| 角色 | 职责 | 技能栈 |
|------|------|--------|
| **算法工程师** | FFT 信号处理、检测引擎、阈值校准 | DSP / 生物医学信号处理 |
| **Flutter 工程师** | 跨平台 UI、BLoC 状态管理、BLE 集成 | Dart / Flutter / GetIt |
| **后端工程师** | Supabase 云同步、数据库设计 | PostgreSQL / Supabase SDK |
| **测试工程师** | 单元测试、信号仿真 | flutter_test |

### 技术栈总览

```
Frontend:  Flutter 3.44 + Dart 3.12
State:     flutter_bloc 8.x + equatable
DI:        get_it 8.x
Storage:   Hive 2.x (本地) + Supabase (云端)
BLE:       flutter_blue_plus
Sensors:   sensors_plus + geolocator
PDF:       pdf + printing
Test:      flutter_test
```

---

## 三、Demo 视频说明

### 视频结构 (建议 3 分钟)

| 时间 | 场景 | 内容 |
|------|------|------|
| 0:00-0:15 | 片头 | App 图标 + 标题 "Parkinson Monitor" |
| 0:15-0:40 | 设备连接 | BLE 扫描 → 发现智能手表 → 连接成功振动反馈 |
| 0:40-1:10 | 传感器校准 | 设置 → 点击"开始校准" → 行走 6 秒 → 个性化阈值 |
| 1:10-1:50 | 实时监测 | 户外模式 → 实时加速度波形图 → 指标面板跳动 |
| 1:50-2:10 | 异常检测 | 模拟 FoG → 状态栏变红 "步态冻结" → 脉冲动画 + 振动 |
| 2:10-2:40 | 数据回顾 | 停止监测 → 历史记录 → 事件时间线 → 导出 PDF |
| 2:40-3:00 | 片尾 | PDF 报告展示 + 免责声明 + 团队 Logo |

### 模拟异常步态方法

- **步态冻结**: 原地快速踏步 5-8Hz 腿抖动作，减小步伐幅度
- **静止性震颤**: 手腕快速 4-6Hz 节律性抖动 (模拟搓丸样震颤)
- **运动迟缓**: 以极慢速度 (0.3-0.5m/s) 小步行走

### 录制建议

- 分辨率: 1080×1920 (竖屏), 帧率: 30fps
- QuickTime (macOS) 或 scrcpy (Android)
- 同步录制手机屏幕 + 手部动作画中画

---

## 四、产品详解

### 功能模块

**首页** — 设备连接状态卡片 (一键连接/断开)、今日摘要 (时长+事件分类计数)、快速开始 (室内/户外双模式)、最近事件预览、功能入口网格

**设备管理** — BLE 扫描列表 (RSSI 信号强度排序)、设备信息 (名称/ID/信号)、连接状态实时反馈 (振动+声音)、自动重连

**实时监测** (核心页面) — 状态横幅 (脉冲动画)、加速度波形图 (fl_chart 120点滚动)、四指标面板 (步频/冻结指数/震颤频率/振幅)、事件时间线、模式切换

**历史记录** — 日期筛选 (今天/本周/本月/全部)、统计摘要横幅、CSV 导出

**设置** — 反馈开关 (声音/振动)、传感器校准 (6 秒基线+自适应阈值)、检测参数手动调整、PDF 导出 (单次/趋势报告)、Supabase 配置、医疗免责声明

### 架构

```
Presentation (Pages + BLoC)
    ↓
Domain (Entities + Repository Interfaces)
    ↓
Data (Repository Impls / BLE / Hive / Supabase)
    ↓
Services (DetectionEngine / BLE / Location / Calibration / Feedback)
    ↓
Core (SignalProcessor / Theme / DI)
```

### 数据流

```
BLE/Phone Sensor → SignalProcessor (6s sliding window)
    → DetectionEngine (FFT → freezeIndex / tremorFreq / cadence)
    → FoG/Tremor/Brady detected? → FeedbackService (vibration + audio)
    → MonitoringRepository → Hive (local) + Supabase (cloud)
    → ReportGenerator → PDF
```

### 检测算法详解

**步态冻结 (Freezing of Gait)** — Freeze Index = totalBandPower(3-8Hz) / totalBandPower(0.5-3Hz)，垂直轴 (accelZ)，FI > 1.8 触发。参考 Moore et al. (2008)。

**静止性震颤 (Resting Tremor)** — 4-6Hz FFT 峰值检测，水平轴 (accelX)，归一化功率 > 0.3 + RMS > 0.05 触发。参考 Deuschl et al. (1998)。

**运动迟缓 (Bradykinesia)** — 幅度 < 0.15g + 步频 < 40/min + 角速度 RMS < 0.3，三维度同时满足触发。

### 测试覆盖

35 单元测试: SignalProcessor (12) + DetectionEngine (11) + Calibration (6) + Serialization (5) + Smoke (1)

---

## 五、GMI Cloud 使用说明

### Supabase 表结构

在 GMI Cloud Supabase 控制台执行:

```sql
-- 会话表
CREATE TABLE sessions (
  id TEXT PRIMARY KEY,
  user_id UUID REFERENCES auth.users,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ,
  mode INTEGER NOT NULL,
  events JSONB DEFAULT '[]',
  total_distance_meters FLOAT DEFAULT 0,
  total_steps INTEGER DEFAULT 0,
  gps_path JSONB DEFAULT '[]',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 事件表
CREATE TABLE events (
  id TEXT PRIMARY KEY,
  session_id TEXT REFERENCES sessions(id) ON DELETE CASCADE,
  user_id UUID REFERENCES auth.users,
  timestamp TIMESTAMPTZ NOT NULL,
  type INTEGER NOT NULL,
  severity INTEGER NOT NULL,
  confidence FLOAT DEFAULT 0,
  freeze_index FLOAT,
  tremor_frequency FLOAT,
  movement_amplitude FLOAT
);

-- 索引
CREATE INDEX idx_sessions_user ON sessions(user_id, start_time DESC);
CREATE INDEX idx_events_user ON events(user_id, timestamp DESC);

-- RLS 安全策略
ALTER TABLE sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
CREATE POLICY "Users own data" ON sessions USING (auth.uid() = user_id);
CREATE POLICY "Users own events" ON events USING (auth.uid() = user_id);
```

### 应用配置

在 `lib/main.dart` 添加:

```dart
await SupabaseSyncService.initialize(
  url: 'https://YOUR_PROJECT.supabase.co',
  anonKey: 'YOUR_ANON_KEY',
);
```

### 数据同步流程

```
Patient App                      GMI Cloud (Supabase)
     │                                  │
     ├─ stopSession()                   │
     │  ├─ saveSession(Hive)            │
     │  └─ uploadSession(Supabase) ────►│ sessions 表
     │     └─ uploadEvents() ──────────►│ events 表
     │                                  │
     └─ fetchSessions() ◄───────────────┤ (医生端查看)
```

### 医生端查询示例

```sql
-- 周报汇总
SELECT type, severity, COUNT(*) as count, AVG(confidence) as avg_conf
FROM events WHERE user_id = 'PATIENT_UUID'
  AND timestamp > NOW() - INTERVAL '7 days'
GROUP BY type, severity;

-- 月度 FoG 趋势
SELECT DATE(timestamp) as date, COUNT(*) as fog_count
FROM events WHERE user_id = 'PATIENT_UUID' AND type = 0
  AND timestamp > NOW() - INTERVAL '30 days'
GROUP BY DATE(timestamp) ORDER BY date;
```

### 安全与隐私

- 数据默认仅存储本地 (Hive)，云同步为可选功能
- Supabase RLS 确保用户数据隔离
- HTTPS/TLS 传输加密
- 支持匿名登录，不采集 PII

---

## 附录

**许可证**: MIT License — 自由使用、修改、分发。

**免责声明**: 本应用为辅助监测工具，不提供医疗诊断。检测结果仅供参考，请咨询专业医生。

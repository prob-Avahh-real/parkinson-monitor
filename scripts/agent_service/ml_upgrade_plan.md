# ML 升级实施计划

> 目标：用 Yi & Hwang (2025) 44KB 开源模型替换 FFT 阈值 FOG 检测
> 保留 FFT 作为震颤频率读数 + 低端设备回退
> 完全兼容现有 Flutter 架构，不改 UI/数据流

---

## 一、升级范围

### 改动的文件（共 4 个）

```
现有文件                             改造内容
────────────────────────────────────────────────────────────
① lib/services/detection_engine.dart   核心替换（FOG 检测从 FI → ML）
② lib/services/ml_model_service.dart   新增（模型加载 + TFLite 推理封装）
③ lib/core/constants/app_constants.dart 新增常量（模型路径、回退阈值）
④ pubspec.yaml                         新增依赖（tflite_flutter）

保留不动的文件（34 个）
所有 UI、BLoC、数据层、BLE、GPS、PDF、Supabase → 不需要任何修改
```

### 架构变化

```
改造前：
  50Hz 传感器 → 6s FFT → FI > 1.8 → 连续确认 → DetectionEvent

改造后：
  50Hz 传感器 ─┬→ [常开] TFLite 模型推理 → FOG 概率 > 阈值 → 连续确认
               │                                           ↓
               └→ [回退] 6s FFT → FI > 阈值（仅在模型加载失败时）→ DetectionEvent
```

---

## 二、执行步骤

### Step 1: 训练模型 + 导出 TFLite（3-5 天）

- **模型**：Yi & Hwang (2025) CNN+GRU+Residual+ECA Attention
- **数据集**：Daphnet FOG（公开，10 位 PD 患者，~280 次 FOG 事件）
- **输出**：`fog_detector.tflite`（~44KB）
- **工具**：Google Colab（免费 GPU）
- **代码**：`scripts/training/train_fog_model.ipynb`

文件产出：
```
scripts/training/
├── train_fog_model.ipynb    ← Colab 训练脚本（下面会写）
└── models/
    └── fog_detector.tflite  ← 产物，放入 Flutter assets
```

### Step 2: 集成到 Flutter（2-3 天）

新增 `ml_model_service.dart`：
```dart
class MlModelService {
  // 加载 TFLite 模型（从 assets 或首次下载）
  Future<void> load();

  // 对 128 点 IMU 窗口做推理
  // 输入: [accelX, accelY, accelZ, gyroX, gyroY, gyroZ] × 128 点
  // 输出: FOG 概率 (0.0-1.0)
  Future<double> predictFogProbability(List<double> signal);

  // 模型是否可用
  bool get isLoaded;

  // 释放资源
  void dispose();
}
```

改造 `detection_engine.dart`（关键改动只在 `_detectFreezingOfGait()`）：
```dart
改造前：
  final fi = _processor.freezeIndex(vertAccel);
  final isFog = fi > _fogFreezeIndexThreshold;

改造后：
  if (_mlModel.isLoaded) {
    final prob = await _mlModel.predictFogProbability(combinedSignal);
    final isFog = prob > fogProbabilityThreshold;  // 默认 0.5
  } else {
    // 回退到 FFT 方法
    final fi = _processor.freezeIndex(vertAccel);
    final isFog = fi > _fogFreezeIndexThreshold;
  }
```

保留原样：
- 连续 3 帧确认 `_fogConsecutiveCount >= _consecutiveThreshold`
- 3 秒防抖 `_debounceDuration`
- Severity 分级（ML 版本用置信度分三级）
- Tremor 和 Bradykinesia 检测（继续用 FFT）
- `currentMetrics` 接口

### Step 3: 验证（2-3 天）

| 测试 | 方法 | 标准 |
|------|------|------|
| 模型加载 | 启动 App 检查模型加载成功 | < 500ms |
| 推理延迟 | 100 次推理平均耗时 | < 30ms |
| 精度对比 | Daphnet 测试集 FI vs ML F1 | ML ≥ 0.95 |
| 回退机制 | 删除模型文件后检测是否正常降级 | FFT 阈值正常 |
| 功耗 | 对比改造前后 1 小时功耗 | Δ < 15% |
| 真实场景 | 模拟 FOG 各 20 次 | 检出率 ≥ 90% |

---

## 三、回退设计

这是关键——ML 不能是单点故障：

```
ml_model_service.load()
  ├─ 成功 → 使用 ML 推理
  └─ 失败（模型不存在/损坏/不兼容）
       └─ isLoaded = false
            └─ detection_engine 自动回退 FFT
```

这样即使模型文件没部署好，App 功能也不受影响。

---

## 四、后续扩展

第一版 ML 替换后，为后续留了接口：

| 扩展方向 | 准备 | 时机 |
|---------|------|------|
| 多分类（FOG/震颤/拖步） | ML 输出已经是概率向量 | 下一版模型 |
| 两阶段（触发器+Transformer） | detection_engine 已支持引擎切换 | 有更多数据后 |
| 自监督预训练 | 计算完全在 Colab，App 端不动 | 需要时再训练 |
| 患者个性化微调（few-shot） | 模型加载接口已预留 | 有标注数据后 |

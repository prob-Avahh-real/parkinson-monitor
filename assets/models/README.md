将训练好的模型文件放入此目录：

1. `fog_detector.tflite` — 44KB 量化 TFLite 模型（从 Colab 训练脚本导出）
2. `scaler_params.json` — 预处理标准化参数（从 Colab 训练脚本导出）

### 训练模型

打开 `scripts/training/train_fog_model.ipynb` 在 Colab 中运行，训练完成后
下载这两个文件放入此目录。

### 临时替代方案

在模型训练完成前，`MlModelService.isLoaded` 会返回 `false`，
`DetectionEngine` 会自动回退到 FFT 阈值模式，功能不受影响。

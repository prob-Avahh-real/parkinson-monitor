import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

/// ML 模型推理服务 — 封装 TFLite 模型加载、预处理、推理
class MlModelService {
  Interpreter? _interpreter;
  Map<String, dynamic>? _scalerParams;
  bool _isLoaded = false;

  /// 模型是否加载成功
  bool get isLoaded => _isLoaded;

  /// ── 模型加载 ──

  /// 从 assets 加载 TFLite 模型和标准化参数
  Future<void> load({
    String modelPath = 'models/fog_detector.tflite',
    String scalerPath = 'models/scaler_params.json',
  }) async {
    try {
      // 加载 TFLite
      _interpreter = await Interpreter.fromAsset(modelPath);
      // 加载标准化参数
      final scalerStr = await rootBundle.loadString(scalerPath);
      _scalerParams = jsonDecode(scalerStr) as Map<String, dynamic>;
      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
      // 不抛异常，由调用方检查 isLoaded
    }
  }

  /// 从文件系统加载（适用于首次下载后缓存）
  Future<void> loadFromFile({
    required String modelPath,
    String? scalerPath,
  }) async {
    try {
      _interpreter = Interpreter.fromFile(File(modelPath));
      if (scalerPath != null) {
        final scalerStr = await File(scalerPath).readAsString();
        _scalerParams = jsonDecode(scalerStr) as Map<String, dynamic>;
      }
      _isLoaded = true;
    } catch (e) {
      _isLoaded = false;
    }
  }

  // ── 推理 ──

  /// 对 IMU 滑动窗口执行 FOG 检测
  ///
  /// [accelX/Y/Z] 和 [gyroX/Y/Z] 必须是等长的时序数据
  /// 长度不足时会自动填充到 window_size
  ///
  /// 返回 FOG 概率 (0.0 ~ 1.0)
  Future<double> predictFogProbability({
    required List<double> accelX,
    required List<double> accelY,
    required List<double> accelZ,
    List<double>? gyroX,
    List<double>? gyroY,
    List<double>? gyroZ,
  }) async {
    if (!_isLoaded || _interpreter == null) {
      return -1.0; // 标记为"不可用"
    }

    final windowSize = _scalerParams?['window_size'] as int? ?? 128;

    // 1. 构建输入张量：取最后 windowSize 点，不足则填充
    final len = accelX.length;
    final input = Float32List(windowSize * 3); // 只使用 3 轴加速度

    for (int i = 0; i < windowSize; i++) {
      final srcIdx = len - windowSize + i;
      if (srcIdx >= 0 && srcIdx < len) {
        input[i * 3] = _normalize(accelX[srcIdx], 0);
        input[i * 3 + 1] = _normalize(accelY[srcIdx], 1);
        input[i * 3 + 2] = _normalize(accelZ[srcIdx], 2);
      }
      // 不足的填 0（已归一化后的 0 = 均值）
    }

    // 2. reshape 为模型输入形状 (1, 128, 3, 1)
    final shapedInput = input.reshape([1, windowSize, 3, 1]);

    // 3. 推理
    final output = Float32List(1); // 单输出: FOG 概率
    _interpreter!.run(shapedInput, output);

    return output[0].toDouble();
  }

  /// 对单批数据推理（批量接口，供内部使用）
  Float64List predictBatch(Float32List input) {
    final output = Float64List(1);
    _interpreter!.run(input, output);
    return output;
  }

  // ── 归一化 ──

  double _normalize(double value, int axis) {
    if (_scalerParams == null) return value;
    final means = _scalerParams!['mean'] as List<dynamic>;
    final scales = _scalerParams!['scale'] as List<dynamic>;
    if (axis >= means.length) return value;
    final mean = (means[axis] as num).toDouble();
    final scale = (scales[axis] as num).toDouble();
    if (scale.abs() < 1e-10) return value;
    return (value - mean) / scale;
  }

  // ── 生命周期 ──

  /// 释放 TFLite  interpreter 资源
  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
  }
}

// ── Float32List reshape 辅助 ──

extension Float32ListReshape on Float32List {
  Float32List reshape(List<int> shape) {
    // TFLite 的 run() 方法接受 List<List<...>> 嵌套格式
    // 但直接把 Float32List 传进去也可以工作
    // 这里为了兼容性，返回自身即可
    return this;
  }
}

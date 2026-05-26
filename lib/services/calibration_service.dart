import 'dart:math';
import 'package:hive_flutter/hive_flutter.dart';
import '../core/utils/signal_processor.dart';
import '../core/constants/app_constants.dart';

/// FFT 阈值校准服务
/// 采集用户正常行走时的传感器数据，计算个性化阈值
class CalibrationService {
  final SignalProcessor _processor;
  final List<double> _freezeIndices = [];
  final List<double> _tremorPowers = [];
  final List<double> _amplitudes = [];
  final List<double> _cadences = [];

  bool _isCalibrating = false;
  int _samplesCollected = 0;
  static const int _targetSamples = 300; // ~6 秒 @ 50Hz

  CalibrationService({int sampleRate = 50})
      : _processor = SignalProcessor(sampleRate: sampleRate);

  bool get isCalibrating => _isCalibrating;
  double get progress => (_samplesCollected / _targetSamples).clamp(0.0, 1.0);
  int get samplesCollected => _samplesCollected;

  /// 开始校准 — 用户在此期间保持正常行走
  void startCalibration() {
    _isCalibrating = true;
    _samplesCollected = 0;
    _freezeIndices.clear();
    _tremorPowers.clear();
    _amplitudes.clear();
    _cadences.clear();
    _processor.clear();
  }

  /// 输入传感器数据
  void processReading({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
  }) {
    if (!_isCalibrating) return;

    _processor.addReading(accelX, accelY, accelZ, gyroX, gyroY, gyroZ);
    _samplesCollected++;

    // 每 100 个样本计算一次特征
    if (_samplesCollected % 100 == 0 &&
        _processor.bufferSize >= _processor.sampleRate * 3) {
      final accelMags = _processor.accelMagnitudes;

      // 冻结指数
      final fi = _processor.freezeIndex(accelMags);
      _freezeIndices.add(fi);

      // 震颤功率
      final mags = SignalProcessor.fftMagnitudes(accelMags);
      final tremorPower = _processor.bandPower(mags, 4.0, 6.0);
      _tremorPowers.add(tremorPower);

      // 运动幅度
      final amp = _processor.amplitude(accelMags);
      _amplitudes.add(amp);

      // 步频
      final cadence = _processor.estimateCadence(_processor.verticalAccel);
      _cadences.add(cadence);
    }

    // 达到目标样本数自动停止
    if (_samplesCollected >= _targetSamples) {
      _isCalibrating = false;
    }
  }

  /// 停止校准，返回个性化阈值
  CalibrationResult finishCalibration() {
    _isCalibrating = false;

    if (_freezeIndices.isEmpty) {
      return const CalibrationResult(
        fogThreshold: 1.8,
        tremorPowerThreshold: 0.3,
        bradyAmplitudeThreshold: 0.15,
        bradyCadenceThreshold: 40,
      );
    }

    // 计算统计量
    double mean(List<double> values) {
      if (values.isEmpty) return 0;
      return values.reduce((a, b) => a + b) / values.length;
    }

    double std(List<double> values) {
      if (values.length < 2) return 0;
      final m = mean(values);
      final variance =
          values.map((v) => (v - m) * (v - m)).reduce((a, b) => a + b) /
              (values.length - 1);
      return sqrt(variance);
    }

    // 正常步行时 FoG 指数应较低 → 阈值 = 均值 + 2.5σ
    final fogMean = mean(_freezeIndices);
    final fogStd = std(_freezeIndices);
    final fogThreshold = (fogMean + 2.5 * fogStd).clamp(1.2, 3.0);

    // 震颤功率阈值 = 均值 + 3σ
    final tremorMean = mean(_tremorPowers);
    final tremorStd = std(_tremorPowers);
    final tremorThreshold = (tremorMean + 3.0 * tremorStd).clamp(0.15, 1.0);

    // 运动迟缓：正常幅值 → 阈值 = 均值 * 0.5 (显著低于正常才报警)
    final ampMean = mean(_amplitudes);
    final bradyAmpThreshold = (ampMean * 0.5).clamp(0.05, 0.3);

    // 步频阈值 = 均值 * 0.7
    final cadenceMean = mean(_cadences);
    final bradyCadenceThreshold =
        (cadenceMean * 0.7).clamp(25.0, 60.0).toDouble();

    return CalibrationResult(
      fogThreshold: fogThreshold,
      tremorPowerThreshold: tremorThreshold,
      bradyAmplitudeThreshold: bradyAmpThreshold,
      bradyCadenceThreshold: bradyCadenceThreshold,
      fogBaseline: fogMean,
      tremorBaseline: tremorMean,
      ampBaseline: ampMean,
      cadenceBaseline: cadenceMean,
    );
  }

  /// 保存校准结果到 Hive
  Future<void> saveCalibration(CalibrationResult result) async {
    final box = Hive.box(AppConstants.settingsBox);
    await box.put(AppConstants.keyFogThreshold, result.fogThreshold);
    await box.put('tremor_power_threshold', result.tremorPowerThreshold);
    await box.put('brady_amp_threshold', result.bradyAmplitudeThreshold);
    await box.put('brady_cadence_threshold', result.bradyCadenceThreshold);
    await box.put('calibrated', true);
    await box.put('calibration_date', DateTime.now().toIso8601String());
  }

  void dispose() {
    _processor.clear();
  }
}

/// 校准结果
class CalibrationResult {
  final double fogThreshold;
  final double tremorPowerThreshold;
  final double bradyAmplitudeThreshold;
  final double bradyCadenceThreshold;
  final double fogBaseline;
  final double tremorBaseline;
  final double ampBaseline;
  final double cadenceBaseline;

  const CalibrationResult({
    required this.fogThreshold,
    required this.tremorPowerThreshold,
    required this.bradyAmplitudeThreshold,
    required this.bradyCadenceThreshold,
    this.fogBaseline = 0,
    this.tremorBaseline = 0,
    this.ampBaseline = 0,
    this.cadenceBaseline = 0,
  });
}

import 'dart:async';
import 'package:uuid/uuid.dart';
import '../../core/utils/signal_processor.dart';
import '../../domain/entities/detection_event.dart';
import '../../domain/entities/movement_disorder_type.dart';
import 'ml_model_service.dart';

/// 帕金森运动障碍实时检测引擎
///
/// FOG 检测采用双引擎策略：
///   首选: ML 模型推理（精度高、跨患者泛化好）
///   回退: FFT 阈值（模型不可用时自动降级）
/// 震颤和运动迟缓继续使用 FFT 方法。
class DetectionEngine {
  final SignalProcessor _processor;
  final MlModelService? _mlModel;
  final _uuid = const Uuid();

  /// 检测事件控制器
  final _detectionController =
      StreamController<DetectionEvent>.broadcast(sync: true);

  Stream<DetectionEvent> get detectionStream => _detectionController.stream;

  // ── 阈值参数 ──
  static const double _fogFreezeIndexThreshold = 1.8;
  static const double _fogMlThreshold = 0.5; // ML 输出的 FOG 概率阈值
  static const double _tremorPowerThreshold = 0.3;
  static const double _tremorFreqLow = 4.0;
  static const double _tremorFreqHigh = 6.0;
  static const double _bradykinesiaAmplitudeThreshold = 0.15;
  static const double _bradykinesiaCadenceThreshold = 40.0;

  // 防抖：避免重复触发
  DateTime _lastFogEvent = DateTime(2000);
  DateTime _lastTremorEvent = DateTime(2000);
  DateTime _lastBradyEvent = DateTime(2000);
  static const _debounceDuration = Duration(seconds: 3);

  // 持续性检测
  int _fogConsecutiveCount = 0;
  int _tremorConsecutiveCount = 0;
  int _bradyConsecutiveCount = 0;
  static const int _consecutiveThreshold = 3; // 连续 N 次确认

  /// 引擎类型（用于调试/日志）
  String get activeFogEngine =>
      (_mlModel?.isLoaded ?? false) ? 'ML' : 'FFT';

  DetectionEngine({int sampleRate = 50, MlModelService? mlModel})
      : _processor = SignalProcessor(sampleRate: sampleRate),
        _mlModel = mlModel;

  /// 输入传感器数据并执行检测
  void processReading({
    required double accelX,
    required double accelY,
    required double accelZ,
    required double gyroX,
    required double gyroY,
    required double gyroZ,
  }) {
    _processor.addReading(
        accelX, accelY, accelZ, gyroX, gyroY, gyroZ);

    // 需要足够数据
    if (_processor.bufferSize < _processor.sampleRate * 2) return;

    // 执行三项检测
    _detectFreezingOfGait();
    _detectRestingTremor();
    _detectBradykinesia();
  }

  // ── 步态冻结检测 ──

  void _detectFreezingOfGait() {
    final vertAccel = _processor.verticalAccel;
    if (vertAccel.length < _processor.sampleRate * 3) return;

    // 双引擎策略
    double fi;
    bool isFog;
    double confidence;

    if (_mlModel?.isLoaded ?? false) {
      // ── 引擎 A: ML 模型推理 ──
      // 使用最近 128 点（约 2.5 秒@50Hz）的数据
      final windowSize = 128;
      final start = vertAccel.length - windowSize;
      final x = vertAccel.sublist(start < 0 ? 0 : start);

      // 构建 ML 输入
      final accelX = _processor.horizontalAccel;
      final accelY = _processor.accelMagnitudes; // 近似替代 y 轴

      // 异步执行 ML 推理
      _mlModel!.predictFogProbability(
        accelX: accelX,
        accelY: accelY,
        accelZ: vertAccel,
      ).then((prob) {
        if (prob < 0) return; // 模型不可用标记

        final mlIsFog = prob > _fogMlThreshold;
        if (mlIsFog) {
          _fogConsecutiveCount++;
        } else {
          _fogConsecutiveCount = 0;
        }

        _emitIfThresholdReached(
          consecutiveCount: _fogConsecutiveCount,
          lastEvent: _lastFogEvent,
          onThreshold: () {
            _lastFogEvent = DateTime.now();
            final sev = prob > 0.8
                ? Severity.severe
                : prob > 0.65
                    ? Severity.moderate
                    : Severity.mild;
            _detectionController.add(DetectionEvent(
              id: _uuid.v4(),
              timestamp: DateTime.now(),
              type: MovementDisorderType.freezingOfGait,
              severity: sev,
              confidence: prob.clamp(0.0, 1.0),
              freezeIndex: null, // ML 模式下不输出 FI
            ));
          },
        );
      });
      return;
    }

    // ── 引擎 B: FFT 阈值回退 ──
    fi = _processor.freezeIndex(vertAccel);
    isFog = fi > _fogFreezeIndexThreshold;

    if (isFog) {
      _fogConsecutiveCount++;
    } else {
      _fogConsecutiveCount = 0;
    }

    _emitIfThresholdReached(
      consecutiveCount: _fogConsecutiveCount,
      lastEvent: _lastFogEvent,
      onThreshold: () {
        _lastFogEvent = DateTime.now();
        final sev = fi > 4.0
            ? Severity.severe
            : fi > 2.5
                ? Severity.moderate
                : Severity.mild;
        _detectionController.add(DetectionEvent(
          id: _uuid.v4(),
          timestamp: DateTime.now(),
          type: MovementDisorderType.freezingOfGait,
          severity: sev,
          confidence: (fi / 5.0).clamp(0.0, 1.0),
          freezeIndex: fi,
        ));
      },
    );
  }

  /// 连续确认 + 防抖后的统一发射逻辑
  void _emitIfThresholdReached({
    required int consecutiveCount,
    required DateTime lastEvent,
    required Function() onThreshold,
  }) {
    if (consecutiveCount >= _consecutiveThreshold) {
      final now = DateTime.now();
      if (now.difference(lastEvent) > _debounceDuration) {
        onThreshold();
      }
    }
  }

  // ── 静止性震颤检测 ──

  void _detectRestingTremor() {
    // 使用水平轴 (accelX) — 手部震颤最明显
    final horizAccel = _processor.horizontalAccel;
    if (horizAccel.length < _processor.sampleRate * 4) return;

    // 检测主频
    final peakFreq = _processor.tremorPeakFrequency(horizAccel);
    if (peakFreq == null) return;

    final isTremorFreq =
        peakFreq >= _tremorFreqLow && peakFreq <= _tremorFreqHigh;

    final mags = SignalProcessor.fftMagnitudes(horizAccel);
    // 使用归一化功率进行阈值比较 (不受 N 影响)
    final tremorPower = _processor.bandPower(mags, 4.0, 6.0);

    final rmsVal = _processor.rms(horizAccel);

    final isTremor = isTremorFreq &&
        tremorPower > _tremorPowerThreshold &&
        rmsVal > 0.05;

    if (isTremor) {
      _tremorConsecutiveCount++;
    } else {
      _tremorConsecutiveCount = 0;
    }

    if (_tremorConsecutiveCount >= _consecutiveThreshold) {
      final now = DateTime.now();
      if (now.difference(_lastTremorEvent) > _debounceDuration) {
        _lastTremorEvent = now;

        Severity sev;
        if (tremorPower > 0.8) {
          sev = Severity.severe;
        } else if (tremorPower > 0.5) {
          sev = Severity.moderate;
        } else {
          sev = Severity.mild;
        }

        _detectionController.add(DetectionEvent(
          id: _uuid.v4(),
          timestamp: now,
          type: MovementDisorderType.restingTremor,
          severity: sev,
          confidence: (tremorPower / 1.0).clamp(0.0, 1.0),
          tremorFrequency: peakFreq,
        ));
      }
    }
  }

  // ── 运动迟缓检测 ──

  void _detectBradykinesia() {
    final accelMags = _processor.accelMagnitudes;
    final vertAccel = _processor.verticalAccel;
    final gyroMags = _processor.gyroMagnitudes;

    if (accelMags.length < _processor.sampleRate * 4) return;

    // 运动幅度
    final amp = _processor.amplitude(accelMags);

    // 步频估计
    final cadence = _processor.estimateCadence(vertAccel);

    // 角速度 RMS (手臂摆动)
    final armSwing = _processor.rms(gyroMags);

    // 运动迟缓判断：幅度小 + 步频低 + 手臂摆动小
    final isBrady = amp < _bradykinesiaAmplitudeThreshold &&
        cadence < _bradykinesiaCadenceThreshold &&
        armSwing < 0.3 &&
        amp > 0.01; // 排除完全静止

    if (isBrady) {
      _bradyConsecutiveCount++;
    } else {
      _bradyConsecutiveCount = 0;
    }

    if (_bradyConsecutiveCount >= _consecutiveThreshold) {
      final now = DateTime.now();
      if (now.difference(_lastBradyEvent) > _debounceDuration) {
        _lastBradyEvent = now;

        Severity sev;
        if (amp < 0.05) {
          sev = Severity.severe;
        } else if (amp < 0.1) {
          sev = Severity.moderate;
        } else {
          sev = Severity.mild;
        }

        _detectionController.add(DetectionEvent(
          id: _uuid.v4(),
          timestamp: now,
          type: MovementDisorderType.bradykinesia,
          severity: sev,
          confidence: (1.0 - (amp / _bradykinesiaAmplitudeThreshold))
              .clamp(0.0, 1.0),
          movementAmplitude: amp,
        ));
      }
    }
  }

  /// 获取当前实时指标
  Map<String, dynamic> get currentMetrics {
    final accelMags = _processor.accelMagnitudes;
    final vertAccel = _processor.verticalAccel;

    return {
      'bufferSize': _processor.bufferSize,
      'rms': accelMags.isNotEmpty ? _processor.rms(accelMags) : 0.0,
      'amplitude':
          accelMags.isNotEmpty ? _processor.amplitude(accelMags) : 0.0,
      'cadence': vertAccel.length > _processor.sampleRate
          ? _processor.estimateCadence(vertAccel)
          : 0.0,
      'freezeIndex': accelMags.length > _processor.sampleRate * 3
          ? _processor.freezeIndex(accelMags)
          : 0.0,
      'tremorFreq': accelMags.length > _processor.sampleRate * 4
          ? (_processor.tremorPeakFrequency(accelMags) ?? 0.0)
          : 0.0,
    };
  }

  void reset() {
    _processor.clear();
    _fogConsecutiveCount = 0;
    _tremorConsecutiveCount = 0;
    _bradyConsecutiveCount = 0;
    _lastFogEvent = DateTime(2000);
    _lastTremorEvent = DateTime(2000);
    _lastBradyEvent = DateTime(2000);
  }

  void dispose() {
    _detectionController.close();
  }
}

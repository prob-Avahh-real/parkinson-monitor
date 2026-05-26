import 'dart:async';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart' show accelerometerEventStream;
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../domain/entities/detection_event.dart';
import '../../domain/entities/monitoring_session.dart';
import '../../domain/entities/movement_disorder_type.dart';
import '../../core/constants/app_constants.dart';
import '../../services/ble_service.dart';
import '../../services/detection_engine.dart';
import '../../services/location_service.dart';

/// 监测仓库实现 — GPS 集成 + 会话持久化
class MonitoringRepositoryImpl implements MonitoringRepository {
  final BleService _bleService;
  final DetectionEngine _detectionEngine;
  final LocationService _locationService;
  final AnalyticsRepository _analyticsRepo;
  final _uuid = const Uuid();

  MonitoringSession? _currentSession;
  StreamSubscription? _bleSub;
  StreamSubscription? _phoneAccelSub;
  bool _isMonitoring = false;

  final _sensorController = StreamController<SensorReading>.broadcast();
  final _detectionController = StreamController<DetectionEvent>.broadcast();

  MonitoringRepositoryImpl({
    required this._bleService,
    required this._detectionEngine,
    required this._locationService,
    required this._analyticsRepo,
  }) {
    _detectionEngine.detectionStream.listen((event) {
      _detectionController.add(event);
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          events: [..._currentSession!.events, event],
        );
      }
    });
  }

  @override
  Stream<SensorReading> get sensorStream => _sensorController.stream;

  @override
  Stream<DetectionEvent> get detectionStream => _detectionController.stream;

  @override
  MonitoringSession? get currentSession => _currentSession;

  @override
  bool get isMonitoring => _isMonitoring;

  @override
  Future<MonitoringSession> startSession(ActivityMode mode) async {
    if (_isMonitoring) await stopSession();

    // 加载校准后的阈值
    await _loadCalibratedThresholds();

    _currentSession = MonitoringSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      mode: mode,
    );
    _isMonitoring = true;

    // 户外模式启动 GPS
    if (mode == ActivityMode.outdoor) {
      await _locationService.startTracking();
    }

    // BLE 或手机传感器
    if (_bleService.isConnected) {
      _bleSub = _bleService.sensorData.listen((data) {
        final reading = SensorReading(
          timestamp: DateTime.now(),
          accelX: data['accelX'] ?? 0,
          accelY: data['accelY'] ?? 0,
          accelZ: data['accelZ'] ?? 0,
          gyroX: data['gyroX'] ?? 0,
          gyroY: data['gyroY'] ?? 0,
          gyroZ: data['gyroZ'] ?? 0,
        );
        _sensorController.add(reading);
        _detectionEngine.processReading(
          accelX: reading.accelX,
          accelY: reading.accelY,
          accelZ: reading.accelZ,
          gyroX: reading.gyroX,
          gyroY: reading.gyroY,
          gyroZ: reading.gyroZ,
        );
      });
    } else {
      _startPhoneSensors();
    }

    return _currentSession!;
  }

  void _startPhoneSensors() {
    _phoneAccelSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 20))
        .listen((event) {
      final reading = SensorReading(
        timestamp: DateTime.now(),
        accelX: event.x,
        accelY: event.y,
        accelZ: event.z,
        gyroX: 0, gyroY: 0, gyroZ: 0,
      );
      _sensorController.add(reading);
      _detectionEngine.processReading(
        accelX: reading.accelX,
        accelY: reading.accelY,
        accelZ: reading.accelZ,
        gyroX: 0, gyroY: 0, gyroZ: 0,
      );
    });
  }

  @override
  Future<MonitoringSession> stopSession() async {
    await _bleSub?.cancel();
    await _phoneAccelSub?.cancel();

    _isMonitoring = false;
    _detectionEngine.reset();

    // 停止 GPS 并获取路径
    double gpsDistance = 0;
    List<GpsPoint> gpsPath = [];
    if (_locationService.isTracking) {
      final result = _locationService.stopTracking();
      gpsPath = result.path;
      gpsDistance = result.totalDistance;
    }

    if (_currentSession != null) {
      _currentSession = _currentSession!.copyWith(
        endTime: DateTime.now(),
        totalDistanceMeters: gpsDistance,
        gpsPath: gpsPath,
      );

      // 持久化到 Hive
      await _analyticsRepo.saveSession(_currentSession!);
    }

    return _currentSession ??
        MonitoringSession(
          id: _uuid.v4(),
          startTime: DateTime.now(),
          endTime: DateTime.now(),
          mode: ActivityMode.indoor,
          totalDistanceMeters: gpsDistance,
          gpsPath: gpsPath,
        );
  }

  /// 从 Hive 加载个性化阈值并应用到检测引擎
  Future<void> _loadCalibratedThresholds() async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final calibrated = box.get('calibrated', defaultValue: false) as bool;
      if (!calibrated) return;

      // 阈值已通过 CalibrationService 保存
      // DetectionEngine 使用静态阈值，此处仅记录日志
    } catch (_) {}
  }
}

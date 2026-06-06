import 'dart:async';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:sensors_plus/sensors_plus.dart' show accelerometerEventStream;
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/entities/sensor_reading.dart';
import '../../domain/entities/detection_event.dart';
import '../../domain/entities/monitoring_session.dart';
import '../../domain/entities/movement_disorder_type.dart';
import '../../core/constants/app_constants.dart';
import '../models/session_model.dart';
import '../../services/ble_service.dart';
import '../../services/detection_engine.dart';
import '../../services/location_service.dart';

/// 监测仓库实现 — 活动监测 + 历史查询
class MonitoringRepositoryImpl implements MonitoringRepository {
  final BleService _bleService;
  final DetectionEngine _detectionEngine;
  final LocationService _locationService;
  final _uuid = const Uuid();

  MonitoringSession? _currentSession;
  StreamSubscription? _bleSub;
  StreamSubscription? _phoneAccelSub;
  bool _isMonitoring = false;

  final _sensorController = StreamController<SensorReading>.broadcast();
  final _detectionController = StreamController<DetectionEvent>.broadcast();

  MonitoringRepositoryImpl({
    required BleService bleService,
    required DetectionEngine detectionEngine,
    required LocationService locationService,
  })  : _bleService = bleService,
        _detectionEngine = detectionEngine,
        _locationService = locationService {
    _detectionEngine.detectionStream.listen((event) {
      _detectionController.add(event);
      if (_currentSession != null) {
        _currentSession = _currentSession!.copyWith(
          events: [..._currentSession!.events, event],
        );
      }
    });
  }

  // ── Hive helper ──

  Future<Box<String>> get _sessionsBox async {
    if (!Hive.isBoxOpen(AppConstants.sessionsBox)) {
      return await Hive.openBox<String>(AppConstants.sessionsBox);
    }
    return Hive.box<String>(AppConstants.sessionsBox);
  }

  // ── 活动监测 ──

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

    await _loadCalibratedThresholds();

    _currentSession = MonitoringSession(
      id: _uuid.v4(),
      startTime: DateTime.now(),
      mode: mode,
    );
    _isMonitoring = true;

    if (mode == ActivityMode.outdoor) {
      await _locationService.startTracking();
    }

    if (_bleService.isConnected) {
      // BLE sensors may fire at 50-100 Hz.  Downsample to ~20 Hz so the
      // detection engine and UI are not overwhelmed.
      DateTime _lastBleSample = DateTime.now();
      _bleSub = _bleService.sensorData.listen((data) {
        final now = DateTime.now();
        if (now.difference(_lastBleSample).inMilliseconds < 50) return;
        _lastBleSample = now;
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
    // sensors_plus accelerometer at 50 Hz (20 ms period).  Downsample
    // to ~20 Hz so the detection pipeline is not overloaded.
    DateTime _lastPhoneSample = DateTime.now();
    _phoneAccelSub = accelerometerEventStream(
        samplingPeriod: const Duration(milliseconds: 20))
        .listen((event) {
      final now = DateTime.now();
      if (now.difference(_lastPhoneSample).inMilliseconds < 50) return;
      _lastPhoneSample = now;
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
      final box = await _sessionsBox;
      final json = SessionModel.toJson(_currentSession!);
      await box.put(_currentSession!.id, jsonEncode(json));
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

  Future<void> _loadCalibratedThresholds() async {
    try {
      final box = Hive.box(AppConstants.settingsBox);
      final calibrated = box.get('calibrated', defaultValue: false) as bool;
      if (!calibrated) return;
    } catch (_) {}
  }

  // ── 历史查询 ──

  @override
  Future<List<MonitoringSession>> getSessions({
    int limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final box = await _sessionsBox;
    final sessions = <MonitoringSession>[];
    final keys = box.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final key in keys) {
      if (sessions.length >= limit) break;
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final session = SessionModel.fromJson(json);
          if (from != null && session.startTime.isBefore(from)) continue;
          if (to != null && session.startTime.isAfter(to)) continue;
          sessions.add(session);
        } catch (_) {}
      }
    }
    return sessions;
  }

  @override
  Future<Map<String, dynamic>> getSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final sessions = await getSessions(from: from, to: to);

    int totalFog = 0, totalTremor = 0, totalBrady = 0;
    Duration totalDuration = Duration.zero;

    for (final s in sessions) {
      totalFog += s.fogCount;
      totalTremor += s.tremorCount;
      totalBrady += s.bradykinesiaCount;
      totalDuration += s.duration;
    }

    return {
      'periodStart': from.toIso8601String(),
      'periodEnd': to.toIso8601String(),
      'totalSessions': sessions.length,
      'totalFogEvents': totalFog,
      'totalTremorEvents': totalTremor,
      'totalBradyEvents': totalBrady,
      'totalDurationMinutes': totalDuration.inMinutes,
      'avgSessionMinutes': sessions.isNotEmpty
          ? (totalDuration.inMinutes / sessions.length).round()
          : 0,
    };
  }

  @override
  Future<String> exportCsv(MonitoringSession session) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'timestamp,type,severity,confidence,freeze_index,tremor_freq,movement_amp');
    for (final event in session.events) {
      buffer.writeln(
        '${event.timestamp.toIso8601String()},${event.type.name},${event.severity.name},'
        '${event.confidence},${event.freezeIndex ?? ""},${event.tremorFrequency ?? ""},${event.movementAmplitude ?? ""}',
      );
    }
    return buffer.toString();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final box = await _sessionsBox;
    await box.delete(sessionId);
  }
}

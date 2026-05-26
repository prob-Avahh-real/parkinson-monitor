import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/domain/entities/monitoring_session.dart';
import 'package:parkinson_monitor/domain/entities/detection_event.dart';
import 'package:parkinson_monitor/domain/entities/movement_disorder_type.dart';
import 'package:parkinson_monitor/data/models/session_model.dart';
import 'package:parkinson_monitor/data/models/detection_event_adapter.dart';

void main() {
  group('DetectionEventAdapter — JSON 序列化', () {
    test('往返序列化保持数据一致', () {
      final event = DetectionEvent(
        id: 'test-id-001',
        timestamp: DateTime(2026, 5, 25, 14, 30, 0),
        type: MovementDisorderType.freezingOfGait,
        severity: Severity.moderate,
        confidence: 0.85,
        durationSeconds: 2.5,
        freezeIndex: 3.2,
      );

      final json = DetectionEventAdapter.toJson(event);
      final restored = DetectionEventAdapter.fromJson(json);

      expect(restored.id, equals(event.id));
      expect(restored.timestamp, equals(event.timestamp));
      expect(restored.type, equals(event.type));
      expect(restored.severity, equals(event.severity));
      expect(restored.confidence, equals(event.confidence));
      expect(restored.durationSeconds, equals(event.durationSeconds));
      expect(restored.freezeIndex, equals(event.freezeIndex));
      expect(restored.tremorFrequency, isNull);
      expect(restored.movementAmplitude, isNull);
    });

    test('震颤事件序列化', () {
      final event = DetectionEvent(
        id: 'tremor-001',
        timestamp: DateTime(2026, 1, 1),
        type: MovementDisorderType.restingTremor,
        severity: Severity.mild,
        confidence: 0.6,
        tremorFrequency: 5.2,
      );

      final json = DetectionEventAdapter.toJson(event);
      expect(json['type'], equals(1)); // restingTremor index
      expect(json['tremor_frequency'], equals(5.2));

      final restored = DetectionEventAdapter.fromJson(json);
      expect(restored.tremorFrequency, equals(5.2));
    });

    test('运动迟缓事件序列化', () {
      final event = DetectionEvent(
        id: 'brady-001',
        timestamp: DateTime(2026, 6, 1),
        type: MovementDisorderType.bradykinesia,
        severity: Severity.severe,
        confidence: 0.9,
        movementAmplitude: 0.03,
      );

      final json = DetectionEventAdapter.toJson(event);
      expect(json['movement_amplitude'], equals(0.03));

      final restored = DetectionEventAdapter.fromJson(json);
      expect(restored.movementAmplitude, equals(0.03));
    });
  });

  group('SessionModel — JSON 序列化', () {
    test('空会话往返序列化', () {
      final session = MonitoringSession(
        id: 'session-001',
        startTime: DateTime(2026, 5, 25, 10, 0, 0),
        endTime: DateTime(2026, 5, 25, 10, 15, 0),
        mode: ActivityMode.indoor,
      );

      final json = SessionModel.toJson(session);
      final restored = SessionModel.fromJson(json);

      expect(restored.id, equals(session.id));
      expect(restored.startTime, equals(session.startTime));
      expect(restored.endTime, equals(session.endTime));
      expect(restored.mode, equals(session.mode));
      expect(restored.events, isEmpty);
      expect(restored.totalDistanceMeters, equals(0));
    });

    test('含事件和 GPS 的户外会话', () {
      final session = MonitoringSession(
        id: 'outdoor-001',
        startTime: DateTime(2026, 5, 25, 8, 0, 0),
        endTime: DateTime(2026, 5, 25, 8, 20, 0),
        mode: ActivityMode.outdoor,
        events: [
          DetectionEvent(
            id: 'ev-1',
            timestamp: DateTime(2026, 5, 25, 8, 5, 0),
            type: MovementDisorderType.freezingOfGait,
            severity: Severity.mild,
            confidence: 0.7,
            freezeIndex: 2.1,
          ),
        ],
        totalDistanceMeters: 450.5,
        totalSteps: 600,
        gpsPath: [
          GpsPoint(
              latitude: 39.9042,
              longitude: 116.4074,
              timestamp: DateTime(2026, 5, 25, 8, 0, 0)),
          GpsPoint(
              latitude: 39.9050,
              longitude: 116.4080,
              timestamp: DateTime(2026, 5, 25, 8, 10, 0)),
        ],
      );

      final json = SessionModel.toJson(session);
      final restored = SessionModel.fromJson(json);

      expect(restored.events.length, equals(1));
      expect(restored.events.first.freezeIndex, equals(2.1));
      expect(restored.totalDistanceMeters, equals(450.5));
      expect(restored.totalSteps, equals(600));
      expect(restored.gpsPath.length, equals(2));
      expect(restored.gpsPath[0].latitude, equals(39.9042));
    });

    test('JSON 编码后可解析', () {
      final session = MonitoringSession(
        id: 'json-test',
        startTime: DateTime(2026, 1, 1),
        mode: ActivityMode.indoor,
        events: [
          DetectionEvent(
            id: 'ev',
            timestamp: DateTime(2026, 1, 1, 12, 0),
            type: MovementDisorderType.restingTremor,
            severity: Severity.moderate,
            confidence: 0.75,
            tremorFrequency: 4.8,
          ),
        ],
      );

      final json = SessionModel.toJson(session);
      final jsonStr = jsonEncode(json);
      final decoded = jsonDecode(jsonStr) as Map<String, dynamic>;
      final restored = SessionModel.fromJson(decoded);

      expect(restored.id, equals('json-test'));
      expect(restored.events.first.tremorFrequency, equals(4.8));
    });
  });
}

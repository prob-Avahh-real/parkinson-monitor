import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/domain/entities/detection_event.dart';
import 'package:parkinson_monitor/domain/entities/movement_disorder_type.dart';
import 'package:parkinson_monitor/data/models/session_model.dart';
import 'package:parkinson_monitor/domain/entities/monitoring_session.dart';

void main() {
  group('DetectionEvent', () {
    test('props are correctly ordered', () {
      final event = DetectionEvent(
        id: 'evt-1',
        timestamp: DateTime(2026, 6, 5, 10, 30),
        type: MovementDisorderType.freezingOfGait,
        severity: Severity.moderate,
        confidence: 0.75,
        freezeIndex: 2.5,
      );
      // id, timestamp, type, severity, confidence,
      // durationSeconds, freezeIndex, tremorFrequency, movementAmplitude
      expect(event.props.length, 9);
      expect(event.props[0], 'evt-1');
      expect(event.props[2], MovementDisorderType.freezingOfGait);
    });

    test('equality check works', () {
      final a = DetectionEvent(
        id: 'evt-1',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.restingTremor,
        severity: Severity.mild,
        confidence: 0.5,
      );
      final b = DetectionEvent(
        id: 'evt-1',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.restingTremor,
        severity: Severity.mild,
        confidence: 0.5,
      );
      expect(a, b);
    });

    test('different confidence makes events unequal', () {
      final a = DetectionEvent(
        id: 'evt-1',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.freezingOfGait,
        severity: Severity.mild,
        confidence: 0.5,
      );
      final b = DetectionEvent(
        id: 'evt-1',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.freezingOfGait,
        severity: Severity.mild,
        confidence: 0.9,
      );
      expect(a, isNot(b));
    });

    test('tremor event has frequency field', () {
      final event = DetectionEvent(
        id: 'evt-2',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.restingTremor,
        severity: Severity.severe,
        confidence: 0.9,
        tremorFrequency: 5.2,
      );
      expect(event.tremorFrequency, 5.2);
      expect(event.freezeIndex, isNull);
    });

    test('bradykinesia event has movement amplitude', () {
      final event = DetectionEvent(
        id: 'evt-3',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.bradykinesia,
        severity: Severity.mild,
        confidence: 0.6,
        movementAmplitude: 0.08,
      );
      expect(event.movementAmplitude, 0.08);
    });

    test('default duration is 0', () {
      final event = DetectionEvent(
        id: 'evt-4',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.freezingOfGait,
        severity: Severity.mild,
        confidence: 0.5,
      );
      expect(event.durationSeconds, 0);
    });
  });

  group('Severity', () {
    test('all severity values are distinct', () {
      const values = Severity.values;
      expect(values.length, 3);
      expect(values.toSet().length, values.length);
    });

    test('severity index ordering: mild < moderate < severe', () {
      expect(Severity.mild.index, lessThan(Severity.moderate.index));
      expect(Severity.moderate.index, lessThan(Severity.severe.index));
    });
  });

  group('MovementDisorderType', () {
    test('has five types', () {
      expect(MovementDisorderType.values.length, 5);
    });
  });

  group('Session Model', () {
    test('toJson does not throw for valid session', () {
      final session = MonitoringSession(
        id: 'sess-1',
        startTime: DateTime(2026, 6, 5, 10, 0),
        mode: ActivityMode.outdoor,
      );
      final json = SessionModel.toJson(session);
      expect(json['id'], 'sess-1');
      expect(json['mode'], 1);
    });

    test('fromJson restores session fields', () {
      final json = {
        'id': 'sess-1',
        'start_time': '2026-06-05T10:00:00.000Z',
        'mode': 1,
      };
      final session = SessionModel.fromJson(json);
      expect(session.id, 'sess-1');
      expect(session.mode, ActivityMode.outdoor);
    });
  });
}

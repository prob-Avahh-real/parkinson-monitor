import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/presentation/blocs/monitoring/monitoring_bloc.dart';
import 'package:parkinson_monitor/domain/entities/movement_disorder_type.dart';
import 'package:parkinson_monitor/domain/entities/detection_event.dart';

void main() {
  group('MonitoringState', () {
    test('initial state has correct defaults', () {
      const state = MonitoringState();
      expect(state.isMonitoring, isFalse);
      expect(state.mode, ActivityMode.indoor);
      expect(state.status, 'normal');
      expect(state.recentEvents, isEmpty);
      expect(state.metrics, isEmpty);
      expect(state.latestReading, isNull);
    });

    test('copyWith preserves unchanged fields', () {
      final state = MonitoringState(
        isMonitoring: true,
        mode: ActivityMode.outdoor,
        status: 'normal',
      );
      final updated = state.copyWith(status: 'fog');
      expect(updated.isMonitoring, isTrue);
      expect(updated.mode, ActivityMode.outdoor);
      expect(updated.status, 'fog');
    });

    test('copyWith for recentEvents creates new list', () {
      final state = MonitoringState(recentEvents: const []);
      final updated = state.copyWith(isMonitoring: true);
      expect(updated.recentEvents, isNot(same(state.recentEvents)));
    });
  });

  group('MonitoringEvent', () {
    test('StartMonitoring carries mode', () {
      const event = StartMonitoring(ActivityMode.outdoor);
      expect(event.mode, ActivityMode.outdoor);
    });

    test('StopMonitoring is value type', () {
      const a = StopMonitoring();
      const b = StopMonitoring();
      expect(a, b);
    });

    test('DetectionReceived carries event data', () {
      final detection = DetectionEvent(
        id: 'evt-1',
        timestamp: DateTime(2026, 6, 5),
        type: MovementDisorderType.restingTremor,
        severity: Severity.moderate,
        confidence: 0.7,
        tremorFrequency: 5.0,
      );
      final event = DetectionReceived(detection);
      expect(event.event.type, MovementDisorderType.restingTremor);
      expect(event.event.tremorFrequency, 5.0);
    });
  });

  group('DeviceState', () {
    test('initial state is disconnected', () {
      const state = DeviceState();
      expect(state.isConnected, isFalse);
      expect(state.isScanning, isFalse);
    });

    test('copyWith changes connection state', () {
      const state = DeviceState();
      final updated = state.copyWith(isConnected: true);
      expect(updated.isConnected, isTrue);
    });
  });
}

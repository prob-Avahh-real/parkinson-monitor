part of 'monitoring_bloc.dart';

class MonitoringState {
  final bool isMonitoring;
  final ActivityMode mode;
  final DateTime? sessionStart;
  final String status; // 'normal', 'fog', 'tremor', 'brady'
  final List<DetectionEvent> recentEvents;
  final SensorReading? latestReading;
  final Map<String, dynamic> metrics;

  const MonitoringState({
    this.isMonitoring = false,
    this.mode = ActivityMode.indoor,
    this.sessionStart,
    this.status = 'normal',
    this.recentEvents = const [],
    this.latestReading,
    this.metrics = const {},
  });

  MonitoringState copyWith({
    bool? isMonitoring,
    ActivityMode? mode,
    DateTime? sessionStart,
    String? status,
    List<DetectionEvent>? recentEvents,
    SensorReading? latestReading,
    Map<String, dynamic>? metrics,
  }) {
    return MonitoringState(
      isMonitoring: isMonitoring ?? this.isMonitoring,
      mode: mode ?? this.mode,
      sessionStart: sessionStart ?? this.sessionStart,
      status: status ?? this.status,
      recentEvents: recentEvents ?? this.recentEvents,
      latestReading: latestReading ?? this.latestReading,
      metrics: metrics ?? this.metrics,
    );
  }
}

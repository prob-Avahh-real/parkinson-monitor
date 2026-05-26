part of 'monitoring_bloc.dart';

sealed class MonitoringEvent {
  const MonitoringEvent();
}

class StartMonitoring extends MonitoringEvent {
  final ActivityMode mode;
  const StartMonitoring(this.mode);
}

class StopMonitoring extends MonitoringEvent {
  const StopMonitoring();
}

class SensorDataReceived extends MonitoringEvent {
  final SensorReading reading;
  const SensorDataReceived(this.reading);
}

class DetectionReceived extends MonitoringEvent {
  final DetectionEvent event;
  const DetectionReceived(this.event);
}

class UpdateMetrics extends MonitoringEvent {
  final Map<String, dynamic> metrics;
  const UpdateMetrics(this.metrics);
}

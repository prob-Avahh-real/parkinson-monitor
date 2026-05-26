import 'package:equatable/equatable.dart';
import 'movement_disorder_type.dart';
import 'detection_event.dart';

/// GPS 路径点
class GpsPoint extends Equatable {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  const GpsPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [latitude, longitude, timestamp];
}

/// 一次监测会话
class MonitoringSession extends Equatable {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final ActivityMode mode;
  final List<DetectionEvent> events;
  final double totalDistanceMeters;
  final int totalSteps;
  final List<GpsPoint> gpsPath;

  const MonitoringSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.mode,
    this.events = const [],
    this.totalDistanceMeters = 0,
    this.totalSteps = 0,
    this.gpsPath = const [],
  });

  Duration get duration =>
      (endTime ?? DateTime.now()).difference(startTime);

  int get fogCount =>
      events.where((e) => e.type == MovementDisorderType.freezingOfGait).length;

  int get tremorCount =>
      events.where((e) => e.type == MovementDisorderType.restingTremor).length;

  int get bradykinesiaCount =>
      events.where((e) => e.type == MovementDisorderType.bradykinesia).length;

  MonitoringSession copyWith({
    DateTime? endTime,
    List<DetectionEvent>? events,
    double? totalDistanceMeters,
    int? totalSteps,
    List<GpsPoint>? gpsPath,
  }) {
    return MonitoringSession(
      id: id,
      startTime: startTime,
      endTime: endTime ?? this.endTime,
      mode: mode,
      events: events ?? this.events,
      totalDistanceMeters: totalDistanceMeters ?? this.totalDistanceMeters,
      totalSteps: totalSteps ?? this.totalSteps,
      gpsPath: gpsPath ?? this.gpsPath,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startTime,
        endTime,
        mode,
        events,
        totalDistanceMeters,
        totalSteps,
        gpsPath,
      ];
}

import '../../domain/entities/monitoring_session.dart';
import '../../domain/entities/movement_disorder_type.dart';
import 'detection_event_adapter.dart';

/// MonitoringSession 的 JSON 序列化 + GPS 路径点
class SessionModel {
  static Map<String, dynamic> toJson(MonitoringSession session) {
    return {
      'id': session.id,
      'start_time': session.startTime.toIso8601String(),
      'end_time': session.endTime?.toIso8601String(),
      'mode': session.mode.index,
      'events': session.events
          .map((e) => DetectionEventAdapter.toJson(e))
          .toList(),
      'total_distance_meters': session.totalDistanceMeters,
      'total_steps': session.totalSteps,
      'gps_path': session.gpsPath
          .map((p) => [p.latitude, p.longitude, p.timestamp.toIso8601String()])
          .toList(),
    };
  }

  static MonitoringSession fromJson(Map<String, dynamic> json) {
    final eventsJson = json['events'] as List<dynamic>? ?? [];
    final gpsPathJson = json['gps_path'] as List<dynamic>? ?? [];

    return MonitoringSession(
      id: json['id'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: json['end_time'] != null
          ? DateTime.parse(json['end_time'] as String)
          : null,
      mode: ActivityMode.values[json['mode'] as int],
      events: eventsJson
          .map((e) =>
              DetectionEventAdapter.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalDistanceMeters:
          (json['total_distance_meters'] as num?)?.toDouble() ?? 0,
      totalSteps: json['total_steps'] as int? ?? 0,
      gpsPath: gpsPathJson.map((p) {
        final arr = p as List<dynamic>;
        return GpsPoint(
          latitude: (arr[0] as num).toDouble(),
          longitude: (arr[1] as num).toDouble(),
          timestamp: DateTime.parse(arr[2] as String),
        );
      }).toList(),
    );
  }
}

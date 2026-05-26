import '../../domain/entities/detection_event.dart';
import '../../domain/entities/movement_disorder_type.dart';

/// DetectionEvent 的 JSON 序列化/反序列化
class DetectionEventAdapter {
  static Map<String, dynamic> toJson(DetectionEvent event) {
    return {
      'id': event.id,
      'timestamp': event.timestamp.toIso8601String(),
      'type': event.type.index,
      'severity': event.severity.index,
      'confidence': event.confidence,
      'duration_seconds': event.durationSeconds,
      'freeze_index': event.freezeIndex,
      'tremor_frequency': event.tremorFrequency,
      'movement_amplitude': event.movementAmplitude,
    };
  }

  static DetectionEvent fromJson(Map<String, dynamic> json) {
    return DetectionEvent(
      id: json['id'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      type: MovementDisorderType.values[json['type'] as int],
      severity: Severity.values[json['severity'] as int],
      confidence: (json['confidence'] as num).toDouble(),
      durationSeconds: (json['duration_seconds'] as num?)?.toDouble() ?? 0,
      freezeIndex: (json['freeze_index'] as num?)?.toDouble(),
      tremorFrequency: (json['tremor_frequency'] as num?)?.toDouble(),
      movementAmplitude: (json['movement_amplitude'] as num?)?.toDouble(),
    );
  }
}

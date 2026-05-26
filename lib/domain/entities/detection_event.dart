import 'package:equatable/equatable.dart';
import 'movement_disorder_type.dart';

/// 检测到的一次运动障碍事件
class DetectionEvent extends Equatable {
  final String id;
  final DateTime timestamp;
  final MovementDisorderType type;
  final Severity severity;
  final double confidence; // 0.0 - 1.0
  final double durationSeconds;
  final double? freezeIndex; // FoG 专用
  final double? tremorFrequency; // 震颤专用 (Hz)
  final double? movementAmplitude; // 运动迟缓专用

  const DetectionEvent({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.severity,
    required this.confidence,
    this.durationSeconds = 0,
    this.freezeIndex,
    this.tremorFrequency,
    this.movementAmplitude,
  });

  @override
  List<Object?> get props => [
        id,
        timestamp,
        type,
        severity,
        confidence,
        durationSeconds,
        freezeIndex,
        tremorFrequency,
        movementAmplitude,
      ];
}

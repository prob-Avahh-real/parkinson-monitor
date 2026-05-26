import '../entities/sensor_reading.dart';
import '../entities/detection_event.dart';
import '../entities/monitoring_session.dart';
import '../entities/movement_disorder_type.dart';

/// 监测仓库接口
abstract class MonitoringRepository {
  /// 传感器数据流 (加速度计 + 陀螺仪)
  Stream<SensorReading> get sensorStream;

  /// 检测事件流
  Stream<DetectionEvent> get detectionStream;

  /// 开始监测会话
  Future<MonitoringSession> startSession(ActivityMode mode);

  /// 结束当前会话
  Future<MonitoringSession> stopSession();

  /// 当前会话
  MonitoringSession? get currentSession;

  /// 会话是否活跃
  bool get isMonitoring;
}

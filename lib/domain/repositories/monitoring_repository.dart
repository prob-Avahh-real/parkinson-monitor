import '../entities/sensor_reading.dart';
import '../entities/detection_event.dart';
import '../entities/monitoring_session.dart';
import '../entities/movement_disorder_type.dart';

/// 监测仓库接口 — 活动监测 + 历史查询
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

  // ── 历史查询 ──

  /// 获取历史会话列表
  Future<List<MonitoringSession>> getSessions({
    int limit = 30,
    DateTime? from,
    DateTime? to,
  });

  /// 获取指定日期范围的统计摘要
  Future<Map<String, dynamic>> getSummary({
    required DateTime from,
    required DateTime to,
  });

  /// 导出数据为 CSV
  Future<String> exportCsv(MonitoringSession session);

  /// 删除会话
  Future<void> deleteSession(String sessionId);
}

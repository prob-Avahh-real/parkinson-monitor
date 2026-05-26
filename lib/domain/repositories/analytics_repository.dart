import '../entities/monitoring_session.dart';

/// 分析仓库接口
abstract class AnalyticsRepository {
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

  /// 保存会话到本地存储
  Future<void> saveSession(MonitoringSession session);

  /// 导出数据为 CSV
  Future<String> exportCsv(MonitoringSession session);

  /// 删除会话
  Future<void> deleteSession(String sessionId);
}

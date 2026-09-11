import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/entities/monitoring_session.dart';
import '../../core/constants/app_constants.dart';
import '../models/session_model.dart';

/// 分析仓库实现 — 使用 JSON 序列化的 Hive 本地存储
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  Future<Box<String>> get _sessionsBox async {
    if (!Hive.isBoxOpen(AppConstants.sessionsBox)) {
      return await Hive.openBox<String>(AppConstants.sessionsBox);
    }
    return Hive.box<String>(AppConstants.sessionsBox);
  }

  @override
  Future<List<MonitoringSession>> getSessions({
    int limit = 30,
    DateTime? from,
    DateTime? to,
  }) async {
    final box = await _sessionsBox;
    final sessions = <MonitoringSession>[];
    final keys = box.keys.toList()
      ..sort((a, b) => b.compareTo(a));

    for (final key in keys) {
      if (sessions.length >= limit) break;
      final jsonStr = box.get(key);
      if (jsonStr != null) {
        try {
          final json = jsonDecode(jsonStr) as Map<String, dynamic>;
          final session = SessionModel.fromJson(json);
          // 日期过滤
          if (from != null && session.startTime.isBefore(from)) continue;
          if (to != null && session.startTime.isAfter(to)) continue;
          sessions.add(session);
        } catch (_) {}
      }
    }
    return sessions;
  }

  @override
  Future<void> saveSession(MonitoringSession session) async {
    final box = await _sessionsBox;
    final json = SessionModel.toJson(session);
    await box.put(session.id, jsonEncode(json));
  }

  @override
  Future<Map<String, dynamic>> getSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    final sessions = await getSessions(from: from, to: to);

    int totalFog = 0, totalTremor = 0, totalBrady = 0;
    Duration totalDuration = Duration.zero;

    for (final s in sessions) {
      totalFog += s.fogCount;
      totalTremor += s.tremorCount;
      totalBrady += s.bradykinesiaCount;
      totalDuration += s.duration;
    }

    return {
      'periodStart': from.toIso8601String(),
      'periodEnd': to.toIso8601String(),
      'totalSessions': sessions.length,
      'totalFogEvents': totalFog,
      'totalTremorEvents': totalTremor,
      'totalBradyEvents': totalBrady,
      'totalDurationMinutes': totalDuration.inMinutes,
      'avgSessionMinutes': sessions.isNotEmpty
          ? (totalDuration.inMinutes / sessions.length).round()
          : 0,
    };
  }

  @override
  Future<String> exportCsv(MonitoringSession session) async {
    final buffer = StringBuffer();
    buffer.writeln(
        'timestamp,type,severity,confidence,freeze_index,tremor_freq,movement_amp');
    for (final event in session.events) {
      buffer.writeln(
        '${event.timestamp.toIso8601String()},${event.type.name},${event.severity.name},'
        '${event.confidence},${event.freezeIndex ?? ""},${event.tremorFrequency ?? ""},${event.movementAmplitude ?? ""}',
      );
    }
    return buffer.toString();
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    final box = await _sessionsBox;
    await box.delete(sessionId);
  }
}

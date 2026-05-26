import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/monitoring_session.dart';
import '../data/models/session_model.dart';
import '../domain/entities/detection_event.dart';

/// Supabase 云端同步服务
class SupabaseSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  /// 初始化 Supabase (应在 main 中调用)
  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  /// 检查是否已配置
  bool get isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  /// 上传会话到 Supabase
  Future<bool> uploadSession(MonitoringSession session) async {
    if (!isConfigured) return false;

    try {
      final json = SessionModel.toJson(session);
      json['user_id'] = _client.auth.currentUser?.id;
      json['created_at'] = DateTime.now().toIso8601String();

      await _client.from('sessions').upsert(json);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 上传会话中的事件
  Future<bool> uploadEvents(
      String sessionId, List<DetectionEvent> events) async {
    if (!isConfigured) return false;

    try {
      final rows = events.map((e) => {
            'id': e.id,
            'session_id': sessionId,
            'timestamp': e.timestamp.toIso8601String(),
            'type': e.type.index,
            'severity': e.severity.index,
            'confidence': e.confidence,
            'freeze_index': e.freezeIndex,
            'tremor_frequency': e.tremorFrequency,
            'movement_amplitude': e.movementAmplitude,
            'user_id': _client.auth.currentUser?.id,
          }).toList();

      await _client.from('events').upsert(rows);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 获取用户历史会话
  Future<List<MonitoringSession>> fetchSessions({int limit = 30}) async {
    if (!isConfigured) return [];

    try {
      final response = await _client
          .from('sessions')
          .select()
          .order('start_time', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// 获取指定日期范围的统计
  Future<Map<String, dynamic>> fetchSummary({
    required DateTime from,
    required DateTime to,
  }) async {
    if (!isConfigured) return {};

    try {
      final response = await _client
          .from('sessions')
          .select()
          .gte('start_time', from.toIso8601String())
          .lte('start_time', to.toIso8601String());

      final sessions = (response as List<dynamic>)
          .map((json) => SessionModel.fromJson(json as Map<String, dynamic>))
          .toList();

      int totalFog = 0, totalTremor = 0, totalBrady = 0;
      for (final s in sessions) {
        totalFog += s.fogCount;
        totalTremor += s.tremorCount;
        totalBrady += s.bradykinesiaCount;
      }

      return {
        'totalSessions': sessions.length,
        'totalFogEvents': totalFog,
        'totalTremorEvents': totalTremor,
        'totalBradyEvents': totalBrady,
      };
    } catch (e) {
      return {};
    }
  }

  /// 登录
  Future<bool> signInAnonymously() async {
    if (!isConfigured) return false;
    try {
      await _client.auth.signInAnonymously();
      return true;
    } catch (_) {
      return false;
    }
  }
}



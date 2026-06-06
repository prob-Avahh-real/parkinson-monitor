import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/utils/result.dart';
import '../core/utils/log.dart';
import '../core/utils/timeout.dart';
import '../domain/entities/monitoring_session.dart';
import '../data/models/session_model.dart';
import '../domain/entities/detection_event.dart';

/// Supabase 云端同步服务
///
/// 所有外部调用返回 [Result<T>]，强制调用方处理失败路径。
/// 所有 Supabase 调用带超时保护——没有超时等于隐式 bug。
class SupabaseSyncService {
  SupabaseClient get _client => Supabase.instance.client;

  static Future<void> initialize({
    required String url,
    required String anonKey,
  }) async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  bool get isConfigured {
    try {
      Supabase.instance.client;
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<Result<void>> uploadSession(MonitoringSession session) async {
    if (!isConfigured) {
      return const Failure(AppError(message: 'Supabase 未配置', code: 'SUPABASE_NOT_CONFIGURED'));
    }
    return timeout(
      () async {
        final json = SessionModel.toJson(session);
        json['user_id'] = _client.auth.currentUser?.id;
        json['created_at'] = DateTime.now().toIso8601String();
        await _client.from('sessions').upsert(json);
      },
      limit: DefaultTimeout.supabaseWrite,
      code: 'SUPABASE_SYNC_FAILED',
      message: '云同步失败，数据已保存到本地',
    );
  }

  Future<Result<void>> uploadEvents(String sessionId, List<DetectionEvent> events) async {
    if (!isConfigured) {
      return const Failure(AppError(code: 'SUPABASE_NOT_CONFIGURED', message: 'Supabase 未配置'));
    }
    return timeout(
      () async {
        final rows = events.map((e) => {
          'id': e.id, 'session_id': sessionId, 'timestamp': e.timestamp.toIso8601String(),
          'type': e.type.index, 'severity': e.severity.index, 'confidence': e.confidence,
          'freeze_index': e.freezeIndex, 'tremor_frequency': e.tremorFrequency, 'movement_amplitude': e.movementAmplitude,
          'user_id': _client.auth.currentUser?.id,
        }).toList();
        await _client.from('events').upsert(rows);
      },
      limit: DefaultTimeout.supabaseWrite,
      code: 'SUPABASE_SYNC_FAILED',
      message: '事件同步失败',
    );
  }

  Future<Result<List<MonitoringSession>>> fetchSessions({int limit = 30}) async {
    if (!isConfigured) {
      return const Failure(AppError(code: 'SUPABASE_NOT_CONFIGURED', message: 'Supabase 未配置'));
    }
    return timeout(
      () async {
        final response = await _client.from('sessions').select().order('start_time', ascending: false).limit(limit);
        return (response as List<dynamic>).map((json) => SessionModel.fromJson(json as Map<String, dynamic>)).toList();
      },
      limit: DefaultTimeout.supabaseQuery,
      code: 'SUPABASE_FETCH_FAILED',
      message: '获取历史会话失败',
    );
  }

  Future<Result<Map<String, dynamic>>> fetchSummary({required DateTime from, required DateTime to}) async {
    if (!isConfigured) {
      return const Failure(AppError(code: 'SUPABASE_NOT_CONFIGURED', message: 'Supabase 未配置'));
    }
    return timeout(
      () async {
        final response = await _client.from('sessions').select()
            .gte('start_time', from.toIso8601String()).lte('start_time', to.toIso8601String());
        final sessions = (response as List<dynamic>).map((json) => SessionModel.fromJson(json as Map<String, dynamic>)).toList();
        int totalFog = 0, totalTremor = 0, totalBrady = 0;
        for (final s in sessions) { totalFog += s.fogCount; totalTremor += s.tremorCount; totalBrady += s.bradykinesiaCount; }
        return {'totalSessions': sessions.length, 'totalFogEvents': totalFog, 'totalTremorEvents': totalTremor, 'totalBradyEvents': totalBrady};
      },
      limit: DefaultTimeout.supabaseQuery,
      code: 'SUPABASE_FETCH_FAILED',
      message: '获取统计摘要失败',
    );
  }

  Future<Result<void>> signInAnonymously() async {
    if (!isConfigured) {
      return const Failure(AppError(code: 'SUPABASE_NOT_CONFIGURED', message: 'Supabase 未配置'));
    }
    return timeout(
      () => _client.auth.signInAnonymously(),
      limit: DefaultTimeout.supabaseWrite,
      code: 'SUPABASE_AUTH_FAILED',
      message: '登录失败，请检查网络',
    );
  }
}

import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';

/// 统一结构化日志 — 全项目共用
///
/// 五级：trace / debug / info / warn / error
/// 生产环境 trace/debug 自动静默，error 可路由到 Sentry。
///
/// 用法：
/// ```dart
/// Log.info('BLE', 'Device connected', {'rssi': -45});
/// Log.error('Supabase', 'Sync failed', error, stackTrace);
/// ```
///
/// 不是选择，是约束。所有日志走统一出口。
class Log {
  static Level _minLevel = kDebugMode ? Level.trace : Level.info;
  static void Function(String tag, String message, Level level, Object? error, StackTrace? stack, Map<String, dynamic>? data)? _onError;

  /// 设置最低输出级别
  static void setLevel(Level level) => _minLevel = level;

  /// 注册错误钩子（Sentry / Firebase Crashlytics）
  static void onError(void Function(String tag, String message, Level level, Object? error, StackTrace? stack, Map<String, dynamic>? data) fn) {
    _onError = fn;
  }

  static void trace(String tag, String msg, [Map<String, dynamic>? data]) => _log(tag, msg, Level.trace, null, null, data);
  static void debug(String tag, String msg, [Map<String, dynamic>? data]) => _log(tag, msg, Level.debug, null, null, data);
  static void info(String tag, String msg, [Map<String, dynamic>? data]) => _log(tag, msg, Level.info, null, null, data);
  static void warn(String tag, String msg, [Map<String, dynamic>? data]) => _log(tag, msg, Level.warn, null, null, data);
  static void error(String tag, String msg, [Object? error, StackTrace? stack, Map<String, dynamic>? data]) => _log(tag, msg, Level.error, error, stack, data);

  static void _log(String tag, String message, Level level, Object? error, StackTrace? stack, Map<String, dynamic>? data) {
    if (level.index < _minLevel.index) return;

    final prefix = level.prefix;
    final ts = DateTime.now().toIso8601String();
    final dataStr = data != null && data.isNotEmpty ? ' | $data' : '';

    if (kDebugMode) {
      final line = '[$ts] $prefix [$tag] $message$dataStr';
      if (level == Level.error) {
        developer.log(line, name: tag, error: error, stackTrace: stack, level: 1000);
      } else {
        developer.log(line, name: tag, level: level.index * 200);
      }
    }

    if (level == Level.error && _onError != null) {
      _onError!(tag, message, level, error, stack, data);
    }
  }
}

enum Level {
  trace('TRC'),
  debug('DBG'),
  info('INF'),
  warn('WRN'),
  error('ERR');

  final String prefix;
  const Level(this.prefix);
}

import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// 可观测性服务 — 仅 Sentry 崩溃上报
class MonitoringService {
  static Future<void> initialize() async {
    await SentryFlutter.init(
      (options) {
        options.dsn = _getSentryDsn();
        options.tracesSampleRate = _getTracesSampleRate();
        options.environment = _getEnvironment();
        options.enableAppLifecycleBreadcrumbs = true;
        options.enableUserInteractionBreadcrumbs = true;
        options.enableNetworkBreadcrumbs = true;
        options.beforeSend = _beforeSend;
      },
      appRunner: () async {},
    );
  }

  static String _getSentryDsn() {
    return const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  }

  static double _getTracesSampleRate() {
    return kReleaseMode ? 0.1 : 1.0;
  }

  static String _getEnvironment() {
    return kReleaseMode ? 'production' : 'development';
  }

  static Future<SentryEvent?> _beforeSend(SentryEvent event, {Hint? hint}) async {
    return event;
  }

  // Error Reporting Methods

  static Future<void> captureException(
    dynamic exception, {
    StackTrace? stackTrace,
    Map<String, dynamic>? extra,
  }) async {
    await Sentry.captureException(
      exception,
      stackTrace: stackTrace,
      hint: Hint.withMap(extra),
    );
  }

  static Future<void> captureMessage(
    String message, {
    SentryLevel level = SentryLevel.info,
    Map<String, dynamic>? extra,
  }) async {
    await Sentry.captureMessage(
      message,
      level: level,
      hint: Hint.withMap(extra),
    );
  }

  static Future<void> setUser({
    String? id,
    String? email,
    Map<String, dynamic>? extra,
  }) async {
    await Sentry.configureScope((scope) {
      if (id != null) scope.user = SentryUser(id: id, email: email);
      if (extra != null) scope.setExtras(extra);
    });
  }
}

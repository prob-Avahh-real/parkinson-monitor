import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

class MonitoringService {
  static FirebaseAnalytics? _analytics;
  static FirebasePerformance? _performance;

  static Future<void> initialize() async {
    // Initialize Sentry
    await SentryFlutter.init(
      (options) {
        options.dsn = _getSentryDsn();
        options.tracesSampleRate = _getTracesSampleRate();
        options.environment = _getEnvironment();
        options.release = _getRelease();
        options.enableAppLifecycleBreadcrumbs = true;
        options.enableUserInteractionBreadcrumbs = true;
        options.enableNetworkBreadcrumbs = true;
        options.beforeSend = _beforeSend;
      },
      appRunner: () async {
        // Initialize Firebase
        if (await _shouldInitializeFirebase()) {
          await Firebase.initializeApp();
          _analytics = FirebaseAnalytics.instance;
          _performance = FirebasePerformance.instance;
          await _performance!.setPerformanceCollectionEnabled(true);
        }
      },
    );
  }

  static String _getSentryDsn() {
    // In production, this should come from environment variables
    // For now, return empty string to disable Sentry in development
    return const String.fromEnvironment('SENTRY_DSN', defaultValue: '');
  }

  static double _getTracesSampleRate() {
    // Sample rate for performance monitoring
    // 1.0 = 100% of transactions, 0.1 = 10% of transactions
    return kReleaseMode ? 0.1 : 1.0;
  }

  static String _getEnvironment() {
    return kReleaseMode ? 'production' : 'development';
  }

  static String? _getRelease() {
    // This should be set during build time
    return const String.fromEnvironment('APP_VERSION', defaultValue: null);
  }

  static Future<SentryEvent?> _beforeSend(SentryEvent event, {Hint? hint}) async {
    // Filter out sensitive information or modify events before sending
    return event;
  }

  static Future<bool> _shouldInitializeFirebase() async {
    // Check if Firebase is enabled in environment
    // For now, only initialize in release mode
    return kReleaseMode;
  }

  // Analytics Methods
  static Future<void> logEvent(String name, {Map<String, dynamic>? parameters}) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: name,
        parameters: parameters,
      );
    }
  }

  static Future<void> logScreenView(String screenName) async {
    if (_analytics != null) {
      await _analytics!.logScreenView(screenName: screenName);
    }
  }

  static Future<void> logError(String error, {Map<String, dynamic>? parameters}) async {
    if (_analytics != null) {
      await _analytics!.logEvent(
        name: 'error',
        parameters: {
          'error_message': error,
          ...?parameters,
        },
      );
    }
  }

  // Performance Monitoring Methods
  static Trace? startTrace(String name) {
    if (_performance != null) {
      return _performance!.newTrace(name);
    }
    return null;
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

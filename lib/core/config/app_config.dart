import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _envFile = '.env';

  static Future<void> load() async {
    await dotenv.load(fileName: _envFile);
    _validate();
  }

  /// 校验必要配置项，缺少时输出警告但不阻塞启动
  static void _validate() {
    final warnings = <String>[];

    if (supabaseUrl.isEmpty && enableCloudSync) {
      warnings.add('SUPABASE_URL 未配置，云同步已禁用 (ENABLE_CLOUD_SYNC 应为 false)');
    }

    if (sentryDsn.isEmpty && enableCrashReporting) {
      warnings.add('SENTRY_DSN 未配置，崩溃上报将无效');
    }

    if (environment.isEmpty) {
      warnings.add('ENVIRONMENT 未设置，默认为 development');
    }

    for (final warning in warnings) {
      debugPrint('[AppConfig] ⚠ $warning');
    }
  }

  // Environment
  static String get environment =>
      dotenv.env['ENVIRONMENT'] ?? 'development';

  static bool get isDevelopment => environment == 'development';
  static bool get isProduction => environment == 'production';

  // Supabase
  static String get supabaseUrl =>
      dotenv.env['SUPABASE_URL'] ?? '';
  static String get supabaseAnonKey =>
      dotenv.env['SUPABASE_ANON_KEY'] ?? '';

  // API Configuration
  static int get apiTimeout =>
      int.tryParse(dotenv.env['API_TIMEOUT'] ?? '30000') ?? 30000;
  static int get apiRetryCount =>
      int.tryParse(dotenv.env['API_RETRY_COUNT'] ?? '3') ?? 3;

  // Feature Flags
  static bool get enableCloudSync =>
      dotenv.env['ENABLE_CLOUD_SYNC'] == 'true';
  static bool get enableAnalytics =>
      dotenv.env['ENABLE_ANALYTICS'] == 'true';
  static bool get enableCrashReporting =>
      dotenv.env['ENABLE_CRASH_REPORTING'] == 'true';

  // Monitoring Configuration
  static String get sentryDsn =>
      dotenv.env['SENTRY_DSN'] ?? '';
  static String get sentryEnvironment =>
      dotenv.env['SENTRY_ENVIRONMENT'] ?? environment;
  static double get sentryTracesSampleRate =>
      double.tryParse(dotenv.env['SENTRY_TRACES_SAMPLE_RATE'] ?? '0.1') ?? 0.1;
  static bool get firebaseEnabled =>
      dotenv.env['FIREBASE_ENABLED'] == 'true';

  // Detection Thresholds
  static double get freezeIndexThreshold =>
      double.tryParse(dotenv.env['FREEZE_INDEX_THRESHOLD'] ?? '1.8') ?? 1.8;
  static double get tremorFrequencyMin =>
      double.tryParse(dotenv.env['TREMOR_FREQUENCY_MIN'] ?? '4.0') ?? 4.0;
  static double get tremorFrequencyMax =>
      double.tryParse(dotenv.env['TREMOR_FREQUENCY_MAX'] ?? '6.0') ?? 6.0;
  static double get tremorPowerThreshold =>
      double.tryParse(dotenv.env['TREMOR_POWER_THRESHOLD'] ?? '0.3') ?? 0.3;
  static double get bradykinesiaAmplitudeThreshold =>
      double.tryParse(dotenv.env['BRADYKINESIA_AMPLITUDE_THRESHOLD'] ?? '0.15') ?? 0.15;
  static int get bradykinesiaCadenceThreshold =>
      int.tryParse(dotenv.env['BRADYKINESIA_CADENCE_THRESHOLD'] ?? '40') ?? 40;
  static double get bradykinesiaAngularVelocityThreshold =>
      double.tryParse(dotenv.env['BRADYKINESIA_ANGULAR_VELOCITY_THRESHOLD'] ?? '0.3') ?? 0.3;

  // Sampling Configuration
  static int get sensorSamplingRate =>
      int.tryParse(dotenv.env['SENSOR_SAMPLING_RATE'] ?? '50') ?? 50;
  static int get detectionWindowSize =>
      int.tryParse(dotenv.env['DETECTION_WINDOW_SIZE'] ?? '300') ?? 300;
  static int get confirmationFrames =>
      int.tryParse(dotenv.env['CONFIRMATION_FRAMES'] ?? '3') ?? 3;
  static int get debounceDurationMs =>
      int.tryParse(dotenv.env['DEBOUNCE_DURATION_MS'] ?? '3000') ?? 3000;
}

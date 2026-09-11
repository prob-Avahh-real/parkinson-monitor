import '../constants/app_constants.dart';

/// GMI Cloud 配置项。
///
/// API key 和 Base URL 从 Dart define 中读取，适用于 Flutter 运行时和 CI 构建。
///
/// 示例：
/// flutter run \
///   --dart-define=GMI_CLOUD_API_KEY=your_key \
///   --dart-define=GMI_CLOUD_BASE_URL=https://api.gmi.cloud
class GmiCloudConfig {
  GmiCloudConfig._();

  static String get apiKey =>
      const String.fromEnvironment(AppConstants.gmiCloudApiKeyDartDefine);

  static String get baseUrl => const String.fromEnvironment(
        AppConstants.gmiCloudBaseUrlDartDefine,
        defaultValue: '',
      );

  static bool get isConfigured => apiKey.isNotEmpty && baseUrl.isNotEmpty;
}

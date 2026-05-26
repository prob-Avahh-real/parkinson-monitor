/// 应用常量
class AppConstants {
  AppConstants._();

  static const String appName = 'Parkinson Monitor';
  static const String appTagline = '帕金森运动障碍监测';
  static const String appVersion = '1.0.0';

  // 采样配置
  static const int defaultSampleRate = 50; // Hz
  static const int windowSizeSeconds = 6;
  static const int minBufferForAnalysis = 100; // 最小样本数

  // BLE 配置
  static const Duration bleScanTimeout = Duration(seconds: 15);
  static const Duration bleConnectTimeout = Duration(seconds: 10);

  // 检测阈值 (可在设置中调整)
  static const double fogFreezeIndexThreshold = 1.8;
  static const double tremorFreqLow = 4.0;
  static const double tremorFreqHigh = 6.0;
  static const double bradyAmplitudeThreshold = 0.15;

  // 用户默认设置键
  static const String keySampleRate = 'sample_rate';
  static const String keyFogThreshold = 'fog_threshold';
  static const String keyTremorThreshold = 'tremor_threshold';
  static const String keyAudioFeedback = 'audio_feedback';
  static const String keyVibrationFeedback = 'vibration_feedback';
  static const String keyLastDeviceId = 'last_device_id';
  static const String keyActivityMode = 'activity_mode';

  // GMI Cloud API
  static const String gmiCloudApiKeyDartDefine = 'GMI_CLOUD_API_KEY';
  static const String gmiCloudBaseUrlDartDefine = 'GMI_CLOUD_BASE_URL';

  // 数据库
  static const String sessionsBox = 'sessions';
  static const String eventsBox = 'events';
  static const String settingsBox = 'settings';
}

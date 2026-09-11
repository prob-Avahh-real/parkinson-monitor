import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../data/repositories/monitoring_repository_impl.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../services/ble_service.dart';
import '../../services/detection_engine.dart';
import '../../services/feedback_service.dart';
import '../../services/location_service.dart';
import '../../services/calibration_service.dart';
import '../../services/supabase_sync_service.dart';
import '../../services/gmi_cloud_service.dart';
import '../constants/app_constants.dart';

final sl = GetIt.instance;

/// 初始化依赖注入
Future<void> initDependencies() async {
  await Hive.initFlutter();

  // 打开 Box
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox<String>(AppConstants.sessionsBox);

  // ── 外部服务 ──
  sl.registerLazySingleton<BleService>(() => BleService());
  sl.registerLazySingleton<DetectionEngine>(
      () => DetectionEngine(sampleRate: AppConstants.defaultSampleRate));
  sl.registerLazySingleton<FeedbackService>(() => FeedbackService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<CalibrationService>(
      () => CalibrationService(sampleRate: AppConstants.defaultSampleRate));
  sl.registerLazySingleton<SupabaseSyncService>(() => SupabaseSyncService());
  sl.registerLazySingleton<GmiCloudService>(() => GmiCloudService());

  // ── 仓库 ──
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(bleService: sl()),
  );
  sl.registerLazySingleton<AnalyticsRepository>(
    () => AnalyticsRepositoryImpl(),
  );
  sl.registerLazySingleton<MonitoringRepository>(
    () => MonitoringRepositoryImpl(
      bleService: sl(),
      detectionEngine: sl(),
      locationService: sl(),
      analyticsRepo: sl(),
    ),
  );
}

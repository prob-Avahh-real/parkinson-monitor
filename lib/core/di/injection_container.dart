import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../utils/hive_safe_init.dart';

import '../../domain/repositories/device_repository.dart';
import '../../domain/repositories/monitoring_repository.dart';
import '../../data/repositories/device_repository_impl.dart';
import '../../data/repositories/monitoring_repository_impl.dart';
import '../../services/ble_service.dart';
import '../../services/detection_engine.dart';
import '../../services/feedback_service.dart';
import '../../services/location_service.dart';
import '../../services/calibration_service.dart';
import '../../services/supabase_sync_service.dart';
import '../../services/ml_model_service.dart';
import '../../services/medication_service.dart';
import '../feature_flag.dart';
import '../constants/app_constants.dart';

final sl = GetIt.instance;

/// 初始化依赖注入
Future<void> initDependencies() async {
  await Hive.initFlutter();

  // 安全打开 Box（损坏时自动重建）
  await HiveSafeInit.openBox(AppConstants.settingsBox);
  await HiveSafeInit.openBox<String>(AppConstants.sessionsBox);

  // ── ML 模型服务（feature flag 控制，默认关闭） ──
  if (FeatureFlag('ml_detection_engine').isEnabled) {
    final mlService = MlModelService();
    await mlService.load();
    sl.registerLazySingleton<MlModelService>(() => mlService);
  } else {
    sl.registerLazySingleton<MlModelService>(() => MlModelService());
  }

  // ── 用药记录服务（feature flag 控制，默认关闭） ──
  if (FeatureFlag('medication_tracking').isEnabled) {
    final medService = MedicationService();
    await medService.load();
    sl.registerLazySingleton<MedicationService>(() => medService);
  } else {
    sl.registerLazySingleton<MedicationService>(() => MedicationService());
  }

  // ── 外部服务 ──
  sl.registerLazySingleton<BleService>(() => BleService());
  sl.registerLazySingleton<DetectionEngine>(
      () => DetectionEngine(
        sampleRate: AppConstants.defaultSampleRate,
        mlModel: sl(),
      ));
  sl.registerLazySingleton<FeedbackService>(() => FeedbackService());
  sl.registerLazySingleton<LocationService>(() => LocationService());
  sl.registerLazySingleton<CalibrationService>(
      () => CalibrationService(sampleRate: AppConstants.defaultSampleRate));
  sl.registerLazySingleton<SupabaseSyncService>(() => SupabaseSyncService());

  // ── 仓库 ──
  sl.registerLazySingleton<DeviceRepository>(
    () => DeviceRepositoryImpl(bleService: sl()),
  );
  sl.registerLazySingleton<MonitoringRepository>(
    () => MonitoringRepositoryImpl(
      bleService: sl(),
      detectionEngine: sl(),
      locationService: sl(),
    ),
  );
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/config/app_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'core/utils/log.dart';
import 'presentation/blocs/device/device_bloc.dart';
import 'presentation/blocs/monitoring/monitoring_bloc.dart';
import 'presentation/pages/home_page.dart';
import 'services/monitoring_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Production: suppress debug-level logs
  if (!AppConfig.isDevelopment) Log.setLevel(Level.info);

  await AppConfig.load();

  if (AppConfig.enableCrashReporting) {
    await MonitoringService.initialize();
  }

  GoogleFonts.config.allowRuntimeFetching = false;

  Log.info('App', 'Starting', {
    'environment': AppConfig.environment,
    'cloudSync': AppConfig.enableCloudSync,
    'analytics': AppConfig.enableAnalytics,
    'crashReporting': AppConfig.enableCrashReporting,
  });

  await di.initDependencies();
  Log.info('App', 'Dependencies initialized');

  runApp(const ParkinsonMonitorApp());
}

/// Parkinson Monitor — 帕金森运动障碍可穿戴监测应用
class ParkinsonMonitorApp extends StatelessWidget {
  const ParkinsonMonitorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<DeviceBloc>(
          create: (_) => DeviceBloc(
            deviceRepository: di.sl(),
          ),
        ),
        BlocProvider<MonitoringBloc>(
          create: (_) => MonitoringBloc(
            monitoringRepository: di.sl(),
          ),
        ),
      ],
      child: MaterialApp(
        title: 'Parkinson Monitor',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        home: const HomePage(),
      ),
    );
  }
}

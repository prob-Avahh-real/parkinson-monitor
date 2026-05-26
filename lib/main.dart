import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/config/gmi_cloud_config.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';
import 'presentation/blocs/device/device_bloc.dart';
import 'presentation/blocs/monitoring/monitoring_bloc.dart';
import 'presentation/pages/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final gmiApiKey = GmiCloudConfig.apiKey;
  if (gmiApiKey.isNotEmpty) {
    debugPrint('GMI Cloud API key loaded from build config.');
  }

  // 初始化依赖注入
  await di.initDependencies();

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

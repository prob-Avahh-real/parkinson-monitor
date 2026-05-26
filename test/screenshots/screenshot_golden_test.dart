import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/core/theme/app_theme.dart';
import 'package:parkinson_monitor/presentation/blocs/device/device_bloc.dart';
import 'package:parkinson_monitor/presentation/blocs/monitoring/monitoring_bloc.dart';
import 'package:parkinson_monitor/presentation/pages/home_page.dart';
import 'package:parkinson_monitor/presentation/pages/device_scan_page.dart';
import 'package:parkinson_monitor/presentation/pages/settings_page.dart';
import 'package:parkinson_monitor/presentation/pages/monitoring_page.dart';
import 'package:parkinson_monitor/presentation/pages/history_page.dart';
import 'package:parkinson_monitor/domain/repositories/device_repository.dart';
import 'package:parkinson_monitor/domain/repositories/monitoring_repository.dart';
import 'package:parkinson_monitor/domain/entities/sensor_reading.dart';
import 'package:parkinson_monitor/domain/entities/detection_event.dart';
import 'package:parkinson_monitor/domain/entities/monitoring_session.dart';
import 'package:parkinson_monitor/domain/entities/movement_disorder_type.dart';

void main() {
  final size = const Size(390, 844);

  late DeviceBloc deviceBloc;
  late MonitoringBloc monitoringBloc;

  setUp(() {
    deviceBloc = DeviceBloc(deviceRepository: _MockDeviceRepo());
    monitoringBloc = MonitoringBloc(monitoringRepository: _MockMonitoringRepo());
  });

  Widget wrap(Widget child) {
    return MaterialApp(
      theme: AppTheme.lightTheme,
      home: MultiBlocProvider(
        providers: [
          BlocProvider.value(value: deviceBloc),
          BlocProvider.value(value: monitoringBloc),
        ],
        child: child,
      ),
    );
  }

  group('Product Screenshots', () {
    testWidgets('01_home', (tester) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(const HomePage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(find.byType(HomePage), matchesGoldenFile('screenshots/01_home.png'));
    });

    testWidgets('02_device_scan', (tester) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(const DeviceScanPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(find.byType(DeviceScanPage), matchesGoldenFile('screenshots/02_device_scan.png'));
    });

    testWidgets('03_calibration', (tester) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(const SettingsPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(find.byType(SettingsPage), matchesGoldenFile('screenshots/03_calibration.png'));
    });

    testWidgets('04_monitoring', (tester) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(const MonitoringPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(find.byType(MonitoringPage), matchesGoldenFile('screenshots/04_monitoring.png'));
    });

    testWidgets('05_history', (tester) async {
      await tester.binding.setSurfaceSize(size);
      await tester.pumpWidget(wrap(const HistoryPage()));
      await tester.pumpAndSettle(const Duration(seconds: 2));
      await expectLater(find.byType(HistoryPage), matchesGoldenFile('screenshots/05_history.png'));
    });
  });
}

class _MockDeviceRepo implements DeviceRepository {
  @override Stream<Map<String, dynamic>> scanDevices() => const Stream.empty();
  @override Future<bool> connect(String deviceId) async => false;
  @override Future<void> disconnect() async {}
  @override Stream<bool> get connectionState => Stream.value(false);
  @override Map<String, dynamic>? get connectedDevice => null;
}

class _MockMonitoringRepo implements MonitoringRepository {
  @override Stream<SensorReading> get sensorStream => const Stream.empty();
  @override Stream<DetectionEvent> get detectionStream => const Stream.empty();
  @override Future<MonitoringSession> startSession(ActivityMode mode) async {
    return MonitoringSession(id: '', startTime: DateTime.now(), mode: ActivityMode.indoor);
  }
  @override Future<MonitoringSession> stopSession() async {
    return MonitoringSession(id: '', startTime: DateTime.now(), endTime: DateTime.now(), mode: ActivityMode.indoor);
  }
  @override MonitoringSession? get currentSession => null;
  @override bool get isMonitoring => false;
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/presentation/blocs/device/device_bloc.dart';
import 'package:parkinson_monitor/presentation/blocs/monitoring/monitoring_bloc.dart';
import 'package:parkinson_monitor/presentation/pages/home_page.dart';

class MockDeviceBloc extends Mock implements DeviceBloc {}
class MockMonitoringBloc extends Mock implements MonitoringBloc {}

void main() {
  group('HomePage Widget Tests', () {
    late MockDeviceBloc mockDeviceBloc;
    late MockMonitoringBloc mockMonitoringBloc;

    setUp(() {
      mockDeviceBloc = MockDeviceBloc();
      mockMonitoringBloc = MockMonitoringBloc();
    });

    Widget createWidgetUnderTest() {
      return MultiBlocProvider(
        providers: [
          BlocProvider<DeviceBloc>.value(value: mockDeviceBloc),
          BlocProvider<MonitoringBloc>.value(value: mockMonitoringBloc),
        ],
        child: const MaterialApp(home: HomePage()),
      );
    }

    testWidgets('HomePage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.text('Parkinson Monitor'), findsOneWidget);
    });

    testWidgets('HomePage displays device connection status',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Card), findsWidgets);
    });
  });
}

class Mock extends Fake implements DeviceBloc {}

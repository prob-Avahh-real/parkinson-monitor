import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/presentation/blocs/monitoring/monitoring_bloc.dart';
import 'package:parkinson_monitor/presentation/pages/monitoring_page.dart';

class MockMonitoringBloc extends Mock implements MonitoringBloc {}

void main() {
  group('MonitoringPage Widget Tests', () {
    late MockMonitoringBloc mockMonitoringBloc;

    setUp(() {
      mockMonitoringBloc = MockMonitoringBloc();
    });

    Widget createWidgetUnderTest() {
      return BlocProvider<MonitoringBloc>.value(
        value: mockMonitoringBloc,
        child: const MaterialApp(home: MonitoringPage()),
      );
    }

    testWidgets('MonitoringPage renders correctly', (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(Scaffold), findsOneWidget);
    });

    testWidgets('MonitoringPage displays monitoring controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      expect(find.byType(FloatingActionButton), findsOneWidget);
    });
  });
}

class Mock extends Fake implements MonitoringBloc {}

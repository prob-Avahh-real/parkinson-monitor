import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:parkinson_monitor/presentation/blocs/monitoring/monitoring_bloc.dart';
import 'package:parkinson_monitor/presentation/pages/monitoring_page.dart';

/// Minimal test double. A bare `Fake` returns null for every member, which
/// stops the page from building at all, so `state` and `stream` are backed by
/// a real initial state instead.
class MockMonitoringBloc extends Fake implements MonitoringBloc {
  final _states = StreamController<MonitoringState>.broadcast();

  @override
  MonitoringState get state => const MonitoringState();

  @override
  Stream<MonitoringState> get stream => _states.stream;

  void dispose() => _states.close();
}

void main() {
  group('MonitoringPage Widget Tests', () {
    late MockMonitoringBloc mockMonitoringBloc;

    setUp(() {
      mockMonitoringBloc = MockMonitoringBloc();
    });

    tearDown(() {
      mockMonitoringBloc.dispose();
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
      expect(find.text('实时监测'), findsOneWidget);
    });

    testWidgets('MonitoringPage displays monitoring controls',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());

      // The primary control is a full-width ElevatedButton, not a FAB.
      expect(find.byType(ElevatedButton), findsOneWidget);
      expect(find.text('停止监测'), findsOneWidget);
    });
  });
}

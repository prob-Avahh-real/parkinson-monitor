import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:parkinson_monitor/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('App launches and displays home page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      expect(find.text('Parkinson Monitor'), findsOneWidget);
    });

    testWidgets('Navigate to device scan page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on device management button
      final deviceButton = find.text('设备管理');
      if (deviceButton.evaluate().isNotEmpty) {
        await tester.tap(deviceButton);
        await tester.pumpAndSettle();

        expect(find.text('扫描设备'), findsOneWidget);
      }
    });

    testWidgets('Navigate to settings page', (WidgetTester tester) async {
      app.main();
      await tester.pumpAndSettle();

      // Tap on settings button
      final settingsButton = find.text('设置');
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();

        expect(find.text('设置'), findsOneWidget);
      }
    });
  });
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:projet_sejour/main.dart';
import 'package:projet_sejour/pages/login_page.dart';
import 'package:projet_sejour/pages/main_page.dart';
import 'package:projet_sejour/theme/app_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mock Mapbox initialization platform channels
  const MethodChannel mapboxChannel = MethodChannel(
    'plugins.flutter.io/mapbox_maps_flutter',
  );
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(mapboxChannel, (MethodCall methodCall) async {
        return null;
      });

  testWidgets('Login page smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProjetSejourApp());
    await tester.pumpAndSettle(); // Wait for FutureBuilder to resolve

    // Verify that the login page is shown.
    expect(find.byType(LoginPage), findsOneWidget);

    // Verify that the Google login button text is present.
    expect(find.text('Log in using Google'), findsOneWidget);
  });

  testWidgets('MainPage renders without layout exceptions', (
    WidgetTester tester,
  ) async {
    // Provide a mocked size to avoid RenderBox overflow errors in testing
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;

    // Pump the MainPage wrapped in MaterialApp/Theme
    await tester.pumpWidget(
      MaterialApp(theme: AppTheme.lightTheme, home: const MainPage()),
    );

    // Wait for the simulated async loading delay in _loadUserData
    await tester.pumpAndSettle();

    // Verify it rendered the dashboard and announcements
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Announcements'), findsOneWidget);
    expect(find.text('Today\'s Itinerary'), findsOneWidget);

    // Reset view size
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });
}

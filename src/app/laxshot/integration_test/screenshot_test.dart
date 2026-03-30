import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Screenshot integration test suite.
///
/// Navigates through every screen of LaxShot and captures a PNG.
/// Run with:
///   flutter drive --driver=test_driver/integration_test.dart \
///                 --target=integration_test/screenshot_test.dart \
///                 -d <simulator_udid>
///
/// Screenshots land in screenshots/ at the project root.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('LaxShot Screenshots', () {
    setUp(() async {
      final dir = Directory('screenshots');
      if (!dir.existsSync()) dir.createSync(recursive: true);
    });

    Future<void> takeScreenshot(String name) async {
      await binding.takeScreenshot(name);
    }

    testWidgets('01 - Login screen', (tester) async {
      // App renders login screen when unauthenticated (GoRouter redirect)
      await tester.pumpAndSettle(const Duration(seconds: 3));
      await takeScreenshot('01_login');
    });

    testWidgets('02 - Age gate / onboarding', (tester) async {
      await tester.pumpAndSettle();
      // Tap sign up to get to age gate
      final signUpLink = find.text("Don't have an account? Sign up");
      if (signUpLink.evaluate().isNotEmpty) {
        await tester.tap(signUpLink);
        await tester.pumpAndSettle();
      }
      await takeScreenshot('02_age_gate');
    });

    testWidgets('03 - Parental consent screen', (tester) async {
      await tester.pumpAndSettle();
      // Navigate via router directly for screenshot purposes
      await takeScreenshot('03_parental_consent');
    });
  });
}

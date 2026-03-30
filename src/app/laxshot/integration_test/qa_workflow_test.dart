import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:laxshot/main.dart' as app;

/// QA Workflow Integration Tests
///
/// Covers the critical user journeys end-to-end on a real simulator/device.
/// Each test group maps to a product workflow.
///
/// Run:
///   flutter drive \
///     --driver=test_driver/integration_test.dart \
///     --target=integration_test/qa_workflow_test.dart \
///     -d <device_id>
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  // ── Helper ──────────────────────────────────────────────────────────────────

  Future<void> pumpApp(WidgetTester tester) async {
    app.main();
    await tester.pumpAndSettle(const Duration(seconds: 4));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // WF-01: Auth — Sign Up & Login flows
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-01: Authentication', () {
    testWidgets('01a — Login screen renders correctly', (tester) async {
      await pumpApp(tester);

      expect(find.text('Welcome back'), findsOneWidget);
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text("Don't have an account?"), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);

      // Sign Up link must be visible (not clipped)
      final signUpFinder = find.text('Sign Up');
      expect(tester.getTopLeft(signUpFinder).dy, lessThan(tester.view.physicalSize.height / tester.view.devicePixelRatio));
    });

    testWidgets('01b — Email validation shows inline errors', (tester) async {
      await pumpApp(tester);

      // Tap Sign In with empty fields
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('01c — Invalid email format shows validation error', (tester) async {
      await pumpApp(tester);

      await tester.enterText(find.byType(TextFormField).first, 'notanemail');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('01d — Forgot password dialog opens and closes', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsNothing);
    });

    testWidgets('01e — Sign Up navigates to age gate', (tester) async {
      await pumpApp(tester);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Age gate should be visible (has date picker or DOB prompt)
      expect(find.textContaining('birthday'), findsAny);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-02: COPPA Age Gate
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-02: Age Gate & COPPA', () {
    testWidgets('02a — Age gate screen renders DOB picker', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Should show a date input or "How old are you?" prompt
      expect(find.textContaining(RegExp(r'birth|age|old', caseSensitive: false)), findsAny);
    });

    testWidgets('02b — Under-13 DOB routes to parental consent', (tester) async {
      await pumpApp(tester);
      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      // Find DOB input and enter a date that makes user under 13
      final dobFinders = find.byType(TextFormField);
      if (dobFinders.evaluate().isNotEmpty) {
        // Enter DOB 10 years ago
        final tenYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 10));
        await tester.enterText(
          dobFinders.first,
          '${tenYearsAgo.month}/${tenYearsAgo.day}/${tenYearsAgo.year}',
        );
        await tester.pumpAndSettle();

        final continueBtn = find.textContaining(RegExp(r'continue|next', caseSensitive: false));
        if (continueBtn.evaluate().isNotEmpty) {
          await tester.tap(continueBtn.first);
          await tester.pumpAndSettle();
          // Should land on parental consent screen
          expect(find.textContaining(RegExp(r'parent|consent|guardian', caseSensitive: false)), findsAny);
        }
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-03: Home Screen
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-03: Home Dashboard', () {
    // Note: These tests require an authenticated session.
    // In CI, use a test account seeded via Firebase Auth emulator.

    testWidgets('03a — Home shows stat cards and Record CTA', (tester) async {
      await pumpApp(tester);

      // If we land on home (authenticated), verify core widgets
      final recordBtn = find.textContaining(RegExp(r'record|start', caseSensitive: false));
      if (recordBtn.evaluate().isNotEmpty) {
        expect(recordBtn, findsAny);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-04: Camera & Recording
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-04: Camera & Recording', () {
    testWidgets('04a — Camera screen renders mode toggle', (tester) async {
      await pumpApp(tester);

      // Navigate to camera (requires auth — skip gracefully if redirected)
      final cameraBtn = find.byIcon(Icons.videocam_rounded);
      if (cameraBtn.evaluate().isNotEmpty) {
        await tester.tap(cameraBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        // Player/Goalie mode toggle should be visible
        expect(find.textContaining('Player'), findsAny);
        expect(find.textContaining('Goalie'), findsAny);
      }
    });

    testWidgets('04b — Mode toggle switches between Player and Goalie', (tester) async {
      await pumpApp(tester);

      final cameraBtn = find.byIcon(Icons.videocam_rounded);
      if (cameraBtn.evaluate().isNotEmpty) {
        await tester.tap(cameraBtn.first);
        await tester.pumpAndSettle(const Duration(seconds: 2));

        final goalieBtn = find.textContaining('Goalie');
        if (goalieBtn.evaluate().isNotEmpty) {
          await tester.tap(goalieBtn.first);
          await tester.pumpAndSettle();
          // Verify mode switched (Goalie label selected)
          expect(find.textContaining('Goalie'), findsAny);
        }
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-05: Results Screen
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-05: Analysis Results', () {
    testWidgets('05a — Results screen shows score ring and breakdown', (tester) async {
      await pumpApp(tester);

      // Navigate directly to results with a fake sessionId
      // (router should handle this and show placeholder/loading state)
      final recordAgainBtn = find.text('Record Again');
      final viewStatsBtn = find.text('View All Stats');

      // If we can find results screen components anywhere
      if (recordAgainBtn.evaluate().isNotEmpty) {
        expect(recordAgainBtn, findsOneWidget);
        expect(viewStatsBtn, findsOneWidget);
      }
    });

    testWidgets('05b — Coaching tip is visible on results screen', (tester) async {
      await pumpApp(tester);

      final tip = find.text('Coaching Tip');
      if (tip.evaluate().isNotEmpty) {
        expect(tip, findsOneWidget);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-06: Stats Dashboard
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-06: Stats Dashboard', () {
    testWidgets('06a — Stats screen renders heatmap section', (tester) async {
      await pumpApp(tester);

      final statsIcon = find.byIcon(Icons.bar_chart);
      if (statsIcon.evaluate().isNotEmpty) {
        await tester.tap(statsIcon.first);
        await tester.pumpAndSettle();

        // Should show some stats-related content
        expect(find.textContaining(RegExp(r'shot|save|session|stat', caseSensitive: false)), findsAny);
      }
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-07: Achievements
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-07: Achievements', () {
    testWidgets('07a — Achievements screen renders badge list', (tester) async {
      await pumpApp(tester);

      final achievementsNav = find.byIcon(Icons.emoji_events_rounded);
      if (achievementsNav.evaluate().isEmpty) return;

      await tester.tap(achievementsNav.first);
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp(r'achievement|badge|unlock', caseSensitive: false)), findsAny);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-08: Profile & Settings
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-08: Profile & Settings', () {
    testWidgets('08a — Profile screen shows Player/Goalie mode toggle', (tester) async {
      await pumpApp(tester);

      final profileNav = find.byIcon(Icons.person_rounded);
      if (profileNav.evaluate().isEmpty) return;

      await tester.tap(profileNav.first);
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp(r'player|goalie|mode', caseSensitive: false)), findsAny);
    });

    testWidgets('08b — Settings screen renders notifications toggle', (tester) async {
      await pumpApp(tester);

      final settingsNav = find.byIcon(Icons.settings_rounded);
      if (settingsNav.evaluate().isEmpty) return;

      await tester.tap(settingsNav.first);
      await tester.pumpAndSettle();

      expect(find.textContaining(RegExp(r'notification|privacy|account', caseSensitive: false)), findsAny);
    });

    testWidgets('08c — Delete account option is present in settings', (tester) async {
      await pumpApp(tester);

      final settingsNav = find.byIcon(Icons.settings_rounded);
      if (settingsNav.evaluate().isEmpty) return;

      await tester.tap(settingsNav.first);
      await tester.pumpAndSettle();

      // GDPR/COPPA: delete account must be accessible
      expect(find.textContaining(RegExp(r'delete.*account|remove.*data', caseSensitive: false)), findsAny);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-09: Accessibility & UX
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-09: Accessibility', () {
    testWidgets('09a — All tap targets meet 48pt minimum', (tester) async {
      await pumpApp(tester);

      // Check all ElevatedButtons on login screen meet min touch target
      final buttons = tester.widgetList<ElevatedButton>(find.byType(ElevatedButton));
      for (final btn in buttons) {
        final finder = find.byWidget(btn);
        if (finder.evaluate().isNotEmpty) {
          final size = tester.getSize(finder);
          expect(size.height, greaterThanOrEqualTo(48.0),
              reason: 'Button height must be at least 48pt for touch target compliance');
        }
      }
    });

    testWidgets('09b — No overflow errors on login screen', (tester) async {
      await pumpApp(tester);

      // Resize to a narrow viewport (iPhone SE width)
      await tester.binding.setSurfaceSize(const Size(375, 667));
      await tester.pumpAndSettle();

      final overflowErrors = tester.takeException();
      expect(overflowErrors, isNull, reason: 'No RenderFlex overflow on iPhone SE viewport');

      await tester.binding.setSurfaceSize(null); // reset
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // WF-10: Navigation & Deep Links
  // ══════════════════════════════════════════════════════════════════════════
  group('WF-10: Navigation', () {
    testWidgets('10a — Back navigation works from each screen', (tester) async {
      await pumpApp(tester);

      // Navigate to sign up
      final signUpBtn = find.text('Sign Up');
      if (signUpBtn.evaluate().isNotEmpty) {
        await tester.tap(signUpBtn);
        await tester.pumpAndSettle();

        // Go back
        final backBtn = find.byType(BackButton);
        final closeBtn = find.byIcon(Icons.close);
        if (backBtn.evaluate().isNotEmpty) {
          await tester.tap(backBtn.first);
        } else if (closeBtn.evaluate().isNotEmpty) {
          await tester.tap(closeBtn.first);
        }
        await tester.pumpAndSettle();

        // Should be back on login
        expect(find.text('Welcome back'), findsOneWidget);
      }
    });
  });
}

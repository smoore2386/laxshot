import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:laxshot/presentation/app.dart';
import 'package:laxshot/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:laxshot/core/constants/app_routes.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  });

  BuildContext routerCtx(WidgetTester tester) {
    return tester.element(find.byType(Scaffold).first);
  }

  testWidgets('All screens render correctly', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: LaxShotApp()));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // ── 1. Home screen ──
    expect(find.text('Connect LaxPod'), findsOneWidget);
    expect(find.text('Ready to record?'), findsOneWidget);
    expect(find.text('Your Stats'), findsOneWidget);
    debugPrint('✓ Home screen');

    // ── 2. Sensor scan screen ──
    await tester.tap(find.text('Connect LaxPod'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Available Devices'), findsOneWidget);
    debugPrint('✓ Sensor scan screen');

    // Navigate back via GoRouter
    GoRouter.of(routerCtx(tester)).go(AppRoutes.home);
    await tester.pumpAndSettle();

    // ── 3. Sensor live screen ──
    GoRouter.of(routerCtx(tester)).push(AppRoutes.sensorLive);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Take a shot!'), findsOneWidget);
    expect(find.text('End Session'), findsOneWidget);
    expect(find.text('0 shots detected'), findsOneWidget);
    debugPrint('✓ Sensor live screen');

    // ── 4. End session → summary screen ──
    await tester.tap(find.text('End Session'));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Session Summary'), findsOneWidget);
    expect(find.text('No shots recorded in this session.'), findsOneWidget);
    debugPrint('✓ Sensor summary screen (empty state)');

    // Go home via icon
    await tester.tap(find.byIcon(Icons.home));
    await tester.pumpAndSettle();

    // ── 5. Shot replay screen (empty) ──
    GoRouter.of(routerCtx(tester)).push(AppRoutes.shotReplayPath(0));
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.text('Shot not found'), findsOneWidget);
    debugPrint('✓ Shot replay screen (empty state)');

    // Go back to home
    GoRouter.of(routerCtx(tester)).go(AppRoutes.home);
    await tester.pumpAndSettle();

    // ── 6. Stats dashboard ──
    GoRouter.of(routerCtx(tester)).push(AppRoutes.stats);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('✓ Stats dashboard screen');

    // Go back
    GoRouter.of(routerCtx(tester)).go(AppRoutes.home);
    await tester.pumpAndSettle();

    // ── 7. Achievements ──
    GoRouter.of(routerCtx(tester)).push(AppRoutes.achievements);
    await tester.pumpAndSettle(const Duration(seconds: 2));
    expect(find.byType(Scaffold), findsWidgets);
    debugPrint('✓ Achievements screen');

    debugPrint('');
    debugPrint('═══ ALL SCREENS VERIFIED ═══');
  });
}

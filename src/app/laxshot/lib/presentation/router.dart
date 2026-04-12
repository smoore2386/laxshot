import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../core/constants/app_routes.dart';
import '../core/config/dev_config.dart';
import '../features/auth/providers/auth_provider.dart';
import '../features/auth/screens/age_gate_screen.dart';
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/parental_consent_screen.dart';
import '../features/auth/screens/signup_screen.dart';
import '../features/camera/screens/camera_screen.dart';
import '../features/analysis/screens/results_screen.dart';
import '../features/stats/screens/stats_dashboard_screen.dart';
import '../features/stats/screens/achievements_screen.dart';
import '../features/profile/screens/profile_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/sensor/screens/sensor_scan_screen.dart';
import '../features/sensor/screens/sensor_live_screen.dart';
import '../features/sensor/screens/sensor_session_summary_screen.dart';
import '../features/sensor/screens/shot_replay_screen.dart';
import '../features/stats/screens/home_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final currentUser = ref.watch(currentUserModelProvider);

  return GoRouter(
    initialLocation: AppRoutes.root,
    redirect: (context, state) {
      final isAuthenticated = authState.valueOrNull != null;
      final isLoading = authState.isLoading || currentUser.isLoading;

      if (isLoading) return null;

      final path = state.uri.path;

      // Dev bypass: skip auth entirely in debug builds
      if (DevConfig.enableDevBypass && path == AppRoutes.devBypass) {
        return AppRoutes.home;
      }

      // Public routes — no redirect needed
      final publicRoutes = [
        AppRoutes.onboarding,
        AppRoutes.parentalConsent,
        AppRoutes.login,
        AppRoutes.signup,
        if (DevConfig.enableDevBypass) AppRoutes.devBypass,
      ];

      if (!isAuthenticated) {
        // Dev bypass: allow all navigation in debug mode
        if (DevConfig.enableDevBypass) {
          // Skip login entirely — go straight to home
          if (path == AppRoutes.root || path == AppRoutes.login) {
            return AppRoutes.home;
          }
          return null;
        }
        if (publicRoutes.any((r) => path.startsWith(r.split(':').first))) {
          return null;
        }
        return AppRoutes.login;
      }

      // Authenticated — check COPPA consent
      final user = currentUser.valueOrNull;
      if (user != null && user.isMinor && !user.parentApproved) {
        if (path != AppRoutes.parentalConsent) {
          return AppRoutes.parentalConsent;
        }
        return null;
      }

      // Redirect root → home
      if (path == AppRoutes.root) return AppRoutes.home;

      // Authenticated user hitting auth screens → home
      if (path == AppRoutes.login ||
          path == AppRoutes.signup ||
          path == AppRoutes.onboarding) {
        return AppRoutes.home;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.root,
        builder: (_, __) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const AgeGateScreen(),
      ),
      GoRoute(
        path: AppRoutes.parentalConsent,
        builder: (_, __) => const ParentalConsentScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (_, __) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const HomeScreen(),
      ),
      GoRoute(
        path: AppRoutes.camera,
        builder: (_, __) => const CameraScreen(),
      ),
      GoRoute(
        path: AppRoutes.results,
        builder: (context, state) {
          final sessionId = state.pathParameters['sessionId']!;
          return ResultsScreen(sessionId: sessionId);
        },
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (_, __) => const StatsDashboardScreen(),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (_, __) => const AchievementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (_, __) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (_, __) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.sensorScan,
        builder: (_, __) => const SensorScanScreen(),
      ),
      GoRoute(
        path: AppRoutes.sensorLive,
        builder: (_, __) => const SensorLiveScreen(),
      ),
      GoRoute(
        path: AppRoutes.sensorSummary,
        builder: (_, __) => const SensorSessionSummaryScreen(),
      ),
      GoRoute(
        path: AppRoutes.shotReplay,
        builder: (context, state) {
          final shotIndex =
              int.tryParse(state.pathParameters['shotIndex'] ?? '0') ?? 0;
          return ShotReplayScreen(shotIndex: shotIndex);
        },
      ),
      // Dev-only bypass route — redirect intercepts this before the builder runs
      if (DevConfig.enableDevBypass)
        GoRoute(
          path: AppRoutes.devBypass,
          builder: (_, __) => const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          ),
        ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
});

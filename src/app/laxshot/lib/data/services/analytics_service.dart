import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider =
    Provider<AnalyticsService>((_) => AnalyticsService());

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  // ── Auth events ───────────────────────────────────────────────────────────

  Future<void> logSignIn(String method) =>
      _analytics.logLogin(loginMethod: method);

  Future<void> logSignUp(String method) =>
      _analytics.logSignUp(signUpMethod: method);

  // ── Recording events ──────────────────────────────────────────────────────

  Future<void> logRecordingStart() =>
      _analytics.logEvent(name: 'recording_start');

  Future<void> logRecordingComplete({int? durationSeconds}) =>
      _analytics.logEvent(
        name: 'recording_complete',
        parameters: {
          if (durationSeconds != null) 'duration_seconds': durationSeconds,
        },
      );

  Future<void> logAnalysisComplete({double? score}) => _analytics.logEvent(
        name: 'analysis_complete',
        parameters: {if (score != null) 'score': score},
      );

  // ── Sensor events ─────────────────────────────────────────────────────────

  Future<void> logSensorConnected({String? deviceId}) => _analytics.logEvent(
        name: 'sensor_connected',
        parameters: {if (deviceId != null) 'device_id': deviceId},
      );

  Future<void> logSensorSessionEnd({
    int? shotCount,
    double? avgScore,
  }) =>
      _analytics.logEvent(
        name: 'sensor_session_end',
        parameters: {
          if (shotCount != null) 'shot_count': shotCount,
          if (avgScore != null) 'avg_score': avgScore,
        },
      );

  Future<void> logSessionSaved() =>
      _analytics.logEvent(name: 'session_saved');

  // ── Achievement events ────────────────────────────────────────────────────

  Future<void> logAchievementUnlock(String achievementId) =>
      _analytics.logEvent(
        name: 'achievement_unlock',
        parameters: {'achievement_id': achievementId},
      );

  // ── Screen tracking (handled by observer, but manual fallback) ────────────

  Future<void> logScreenView(String screenName) =>
      _analytics.logScreenView(screenName: screenName);
}

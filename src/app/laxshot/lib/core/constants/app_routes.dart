class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String onboarding = '/onboarding';
  static const String parentalConsent = '/parental-consent';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String home = '/home';
  static const String camera = '/camera';
  static const String results = '/results/:sessionId';
  static const String stats = '/stats';
  static const String achievements = '/achievements';
  static const String profile = '/profile';
  static const String settings = '/settings';

  // Sensor (BLE LaxPod)
  static const String sensorScan = '/sensor/scan';
  static const String sensorLive = '/sensor/live';
  static const String sensorSummary = '/sensor/summary';
  static const String shotReplay = '/sensor/replay/:shotIndex';

  static String resultsPath(String sessionId) => '/results/$sessionId';
  static String shotReplayPath(int shotIndex) => '/sensor/replay/$shotIndex';

  /// Dev-only bypass route — navigates straight to home without auth.
  /// Only reachable in debug builds.
  static const String devBypass = '/dev/bypass';
}

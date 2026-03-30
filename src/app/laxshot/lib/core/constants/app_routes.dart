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

  static String resultsPath(String sessionId) => '/results/$sessionId';
}

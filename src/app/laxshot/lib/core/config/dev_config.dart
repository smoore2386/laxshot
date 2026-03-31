import 'package:flutter/foundation.dart';

/// Dev-only configuration.
/// All flags in this file are automatically disabled in release builds
/// via [kDebugMode] — no risk of shipping dev shortcuts.

class DevConfig {
  DevConfig._();

  /// When true, the login screen shows a "Dev: Skip Login" button
  /// that bypasses auth and navigates directly to the home screen.
  /// ⚠️ Only active in debug builds. Never ships in release.
  static const bool enableDevBypass = kDebugMode;

  /// Optional: pre-fill email/password on the login screen in debug mode
  /// to save typing during testing. Set to null to disable.
  static const String? devEmail = kDebugMode ? 'dev@laxshot.test' : null;
  static const String? devPassword = kDebugMode ? 'devpass123' : null;
}

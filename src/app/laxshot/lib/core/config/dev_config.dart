import 'package:flutter/foundation.dart';

/// Dev-only configuration.
/// All flags in this file are automatically disabled in release builds
/// via [kDebugMode] — no risk of shipping dev shortcuts.

class DevConfig {
  DevConfig._();

  /// When true, the app bypasses auth and navigates directly to the home screen.
  /// TODO: Set back to `kDebugMode` once real auth flow is needed.
  static const bool enableDevBypass = true;

  /// Optional: pre-fill email/password on the login screen in debug mode
  /// to save typing during testing. Set to null to disable.
  static const String? devEmail = kDebugMode ? 'dev@laxshot.test' : null;
  static const String? devPassword = kDebugMode ? 'devpass123' : null;
}

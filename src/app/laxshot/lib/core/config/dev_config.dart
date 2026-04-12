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

  /// When true, use [FakeBleService] instead of the real BLE stack so the
  /// full sensor flow can be tested without hardware.
  static const bool useFakeBle = kDebugMode;

  /// When true, connect to Firebase Emulator Suite instead of production.
  /// Requires `firebase emulators:start` to be running locally.
  static const bool useEmulator = kDebugMode;

  /// Emulator host — 'localhost' for native, '10.0.2.2' for Android emulator.
  static const String emulatorHost = 'localhost';
}

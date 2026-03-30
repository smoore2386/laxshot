import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFF2D6A4F);       // Lacrosse green
  static const Color accent = Color(0xFFF4A261);         // Gold
  static const Color primaryDark = Color(0xFF1B4332);
  static const Color primaryLight = Color(0xFF52B788);

  // Semantic
  static const Color success = Color(0xFF40916C);
  static const Color warning = Color(0xFFF77F00);
  static const Color error = Color(0xFFD62828);

  // Heat map (blue → red)
  static const Color heatCold = Color(0xFF0077B6);
  static const Color heatLow = Color(0xFF00B4D8);
  static const Color heatMid = Color(0xFFFCA311);
  static const Color heatHigh = Color(0xFFE85D04);
  static const Color heatHot = Color(0xFFD62828);

  // Neutral
  static const Color surface = Color(0xFFF8F9FA);
  static const Color onSurface = Color(0xFF212529);
  static const Color surfaceVariant = Color(0xFFE9ECEF);
  static const Color outline = Color(0xFFCED4DA);
  static const Color border = outline;
  static const Color background = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF212529);
  static const Color textSecondary = Color(0xFF6C757D);

  // Dark mode
  static const Color darkBackground = Color(0xFF121212);
  static const Color darkSurface = Color(0xFF1E1E1E);
  static const Color darkSurfaceVariant = Color(0xFF2C2C2C);
}

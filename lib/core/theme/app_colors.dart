import 'package:flutter/material.dart';

abstract final class AppColors {
  // Backgrounds
  static const background = Color(0xFF0A0A0A);
  static const surface = Color(0xFF111111);
  static const surfaceElevated = Color(0xFF1A1A1A);

  // Borders
  static const border = Color(0xFF222222);
  static const borderSubtle = Color(0xFF1A1A1A);
  static const borderStrong = Color(0xFF3A3A3A);

  // Accent
  static const accent = Color(0xFFC8FF00);
  static const accentDim = Color(0xFF8AAF00);
  static const accentSubtle = Color(0xFF1A2800);

  // Text
  static const textPrimary = Color(0xFFF5F5F5);
  static const textSecondary = Color(0xFF666666);
  static const textDisabled = Color(0xFF333333);

  // Semantic
  static const error = Color(0xFFFF4444);
  static const errorSubtle = Color(0xFF1A0000);
  static const success = Color(0xFF00FF88);

  // Game
  static const given = Color(0xFFF5F5F5);
  static const user = Color(0xFFC8FF00);
  static const notes = Color(0xFF888888);

  // AMOLED variant
  static const amoledBackground = Color(0xFF000000);
}

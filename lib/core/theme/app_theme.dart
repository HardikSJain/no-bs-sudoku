import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_colors.dart';
import 'app_theme_colors.dart';

ThemeData appTheme({String theme = 'dark'}) {
  final isPaper = theme == 'paper';
  final isAmoled = theme == 'amoled';

  final col = isPaper
      ? AppThemeColors.light
      : isAmoled
          ? AppThemeColors.amoled
          : AppThemeColors.dark;

  if (isPaper) {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: col.background,
      colorScheme: ColorScheme.light(
        surface: col.surface,
        primary: col.accent,
        error: col.error,
      ),
      extensions: [col],
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarBrightness: Brightness.light,
          statusBarIconBrightness: Brightness.dark,
        ),
        iconTheme: IconThemeData(color: col.ink3, size: 20),
      ),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
    );
  }

  final bg = isAmoled ? AppColors.amoledBackground : AppColors.background;
  final surface = isAmoled ? AppColors.background : AppColors.surface;

  return ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bg,
    colorScheme: ColorScheme.dark(
      surface: surface,
      primary: AppColors.accent,
      error: AppColors.error,
    ),
    extensions: [col],
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle(
        statusBarBrightness: Brightness.dark,
        statusBarIconBrightness: Brightness.light,
      ),
      iconTheme: IconThemeData(color: AppColors.textSecondary, size: 20),
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

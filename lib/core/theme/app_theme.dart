import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app_theme_colors.dart';

/// The app's one theme.
///
/// There were three — paper, dark and amoled — and a picker in settings. The
/// paper look is the brand, and keeping the other two meant every new surface
/// had to be checked in three places. That is exactly how a card shipped
/// rendering as dark olive in one of them.
ThemeData appTheme() {
  const col = AppThemeColors.light;

  return ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: col.background,
    colorScheme: ColorScheme.light(
      surface: col.surface,
      primary: col.accent,
      error: col.error,
    ),
    extensions: const [col],
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
    // No ripples anywhere. The design uses hard offsets and instant state
    // changes; a material splash reads as a different app.
    splashFactory: NoSplash.splashFactory,
    highlightColor: Colors.transparent,
  );
}

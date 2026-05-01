import 'package:flutter/material.dart';

// Semantic color tokens for every theme variant.
// Access via: Theme.of(context).extension<AppThemeColors>()!
// Or via the BuildContext helper: context.appColors
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  const AppThemeColors({
    required this.background,
    required this.background2,
    required this.paper,
    required this.ink,
    required this.ink2,
    required this.ink3,
    required this.ink4,
    required this.outline,
    required this.accent,
    required this.accentDeep,
    required this.surface,
    required this.surfaceElevated,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.error,
    required this.sun,
    required this.mint,
    required this.lilac,
    required this.peach,
    required this.isLight,
  });

  final Color background;
  final Color background2;
  final Color paper;
  final Color ink;
  final Color ink2;
  final Color ink3;
  final Color ink4;
  final Color outline;
  final Color accent;
  final Color accentDeep;
  final Color surface;
  final Color surfaceElevated;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color error;
  final Color sun;
  final Color mint;
  final Color lilac;
  final Color peach;
  final bool isLight;

  // ── sticker shadow — chunky black offset used in paper theme ──
  List<BoxShadow> get stickerShadow => isLight
      ? [BoxShadow(color: outline, offset: const Offset(4, 4), blurRadius: 0)]
      : [];

  List<BoxShadow> get cardShadow => isLight
      ? [BoxShadow(color: outline, offset: const Offset(3, 3), blurRadius: 0)]
      : [];

  // ── per-digit number pad colors (paper theme) ─────────────────
  static const _padColors = [
    Color(0xFFFF4747), // 1 cherry
    Color(0xFF2D4BFF), // 2 cobalt
    Color(0xFF79E5C0), // 3 mint
    Color(0xFFFFD23F), // 4 sun
    Color(0xFFC9A8FF), // 5 lilac
    Color(0xFFFFB47A), // 6 peach
    Color(0xFFFF4747), // 7 cherry
    Color(0xFF2D4BFF), // 8 cobalt
    Color(0xFF79E5C0), // 9 mint
  ];

  Color padColor(int digit) =>
      isLight ? _padColors[(digit - 1).clamp(0, 8)] : const Color(0xFF1A1A1A);

  // ── difficulty tile colors ─────────────────────────────────────
  static const difficultyColors = {
    'easy':   Color(0xFF79E5C0), // mint
    'medium': Color(0xFFFFD23F), // sun
    'hard':   Color(0xFFFF4747), // cherry
    'expert': Color(0xFFC9A8FF), // lilac
  };

  Color difficultyColor(String difficulty) =>
      isLight ? (difficultyColors[difficulty] ?? accent) : const Color(0xFF1A1A1A);

  // ── factories ─────────────────────────────────────────────────
  static const light = AppThemeColors(
    background:      Color(0xFFF4ECDD),
    background2:     Color(0xFFEDE3CF),
    paper:           Color(0xFFFBF6EA),
    ink:             Color(0xFF1A1814),
    ink2:            Color(0xFF3D362A),
    ink3:            Color(0xFF7A6F5C),
    ink4:            Color(0xFFB8AC93),
    outline:         Color(0xFF1A1814),
    accent:          Color(0xFF2D4BFF),
    accentDeep:      Color(0xFF1F2FB8),
    surface:         Color(0xFFFBF6EA),
    surfaceElevated: Color(0xFFF4ECDD),
    textPrimary:     Color(0xFF1A1814),
    textSecondary:   Color(0xFF7A6F5C),
    textDisabled:    Color(0xFFB8AC93),
    error:           Color(0xFFFF4747),
    sun:             Color(0xFFFFD23F),
    mint:            Color(0xFF79E5C0),
    lilac:           Color(0xFFC9A8FF),
    peach:           Color(0xFFFFB47A),
    isLight:         true,
  );

  static const dark = AppThemeColors(
    background:      Color(0xFF0A0A0A),
    background2:     Color(0xFF111111),
    paper:           Color(0xFF111111),
    ink:             Color(0xFFF5F5F5),
    ink2:            Color(0xFFCCCCCC),
    ink3:            Color(0xFF888888),
    ink4:            Color(0xFF444444),
    outline:         Color(0xFF222222),
    accent:          Color(0xFFC8FF00),
    accentDeep:      Color(0xFF8AAF00),
    surface:         Color(0xFF111111),
    surfaceElevated: Color(0xFF1A1A1A),
    textPrimary:     Color(0xFFF5F5F5),
    textSecondary:   Color(0xFF666666),
    textDisabled:    Color(0xFF333333),
    error:           Color(0xFFFF4444),
    sun:             Color(0xFFFFD23F),
    mint:            Color(0xFF79E5C0),
    lilac:           Color(0xFFC9A8FF),
    peach:           Color(0xFFFFB47A),
    isLight:         false,
  );

  static const amoled = AppThemeColors(
    background:      Color(0xFF000000),
    background2:     Color(0xFF0A0A0A),
    paper:           Color(0xFF0A0A0A),
    ink:             Color(0xFFF5F5F5),
    ink2:            Color(0xFFCCCCCC),
    ink3:            Color(0xFF888888),
    ink4:            Color(0xFF444444),
    outline:         Color(0xFF1A1A1A),
    accent:          Color(0xFFC8FF00),
    accentDeep:      Color(0xFF8AAF00),
    surface:         Color(0xFF0A0A0A),
    surfaceElevated: Color(0xFF111111),
    textPrimary:     Color(0xFFF5F5F5),
    textSecondary:   Color(0xFF666666),
    textDisabled:    Color(0xFF333333),
    error:           Color(0xFFFF4444),
    sun:             Color(0xFFFFD23F),
    mint:            Color(0xFF79E5C0),
    lilac:           Color(0xFFC9A8FF),
    peach:           Color(0xFFFFB47A),
    isLight:         false,
  );

  @override
  AppThemeColors copyWith({
    Color? background, Color? background2, Color? paper,
    Color? ink, Color? ink2, Color? ink3, Color? ink4, Color? outline,
    Color? accent, Color? accentDeep, Color? surface, Color? surfaceElevated,
    Color? textPrimary, Color? textSecondary, Color? textDisabled,
    Color? error, Color? sun, Color? mint, Color? lilac, Color? peach,
    bool? isLight,
  }) {
    return AppThemeColors(
      background:      background      ?? this.background,
      background2:     background2     ?? this.background2,
      paper:           paper           ?? this.paper,
      ink:             ink             ?? this.ink,
      ink2:            ink2            ?? this.ink2,
      ink3:            ink3            ?? this.ink3,
      ink4:            ink4            ?? this.ink4,
      outline:         outline         ?? this.outline,
      accent:          accent          ?? this.accent,
      accentDeep:      accentDeep      ?? this.accentDeep,
      surface:         surface         ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      textPrimary:     textPrimary     ?? this.textPrimary,
      textSecondary:   textSecondary   ?? this.textSecondary,
      textDisabled:    textDisabled    ?? this.textDisabled,
      error:           error           ?? this.error,
      sun:             sun             ?? this.sun,
      mint:            mint            ?? this.mint,
      lilac:           lilac           ?? this.lilac,
      peach:           peach           ?? this.peach,
      isLight:         isLight         ?? this.isLight,
    );
  }

  @override
  AppThemeColors lerp(AppThemeColors? other, double t) {
    if (other == null) return this;
    return AppThemeColors(
      background:      Color.lerp(background, other.background, t)!,
      background2:     Color.lerp(background2, other.background2, t)!,
      paper:           Color.lerp(paper, other.paper, t)!,
      ink:             Color.lerp(ink, other.ink, t)!,
      ink2:            Color.lerp(ink2, other.ink2, t)!,
      ink3:            Color.lerp(ink3, other.ink3, t)!,
      ink4:            Color.lerp(ink4, other.ink4, t)!,
      outline:         Color.lerp(outline, other.outline, t)!,
      accent:          Color.lerp(accent, other.accent, t)!,
      accentDeep:      Color.lerp(accentDeep, other.accentDeep, t)!,
      surface:         Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      textPrimary:     Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary:   Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled:    Color.lerp(textDisabled, other.textDisabled, t)!,
      error:           Color.lerp(error, other.error, t)!,
      sun:             Color.lerp(sun, other.sun, t)!,
      mint:            Color.lerp(mint, other.mint, t)!,
      lilac:           Color.lerp(lilac, other.lilac, t)!,
      peach:           Color.lerp(peach, other.peach, t)!,
      isLight:         t < 0.5 ? isLight : other.isLight,
    );
  }
}

extension AppThemeX on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.dark;

  static AppThemeColors forTheme(String theme) {
    return switch (theme) {
      'paper'  => AppThemeColors.light,
      'amoled' => AppThemeColors.amoled,
      _        => AppThemeColors.dark,
    };
  }
}

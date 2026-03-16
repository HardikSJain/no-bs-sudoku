import 'package:flutter/services.dart';

/// Centralized haptic feedback with distinct patterns for game events.
class Haptics {
  Haptics._();

  /// Light tap — correct number placement.
  static void correctPlacement() => HapticFeedback.lightImpact();

  /// Heavy thud — mistake.
  static void mistake() => HapticFeedback.heavyImpact();

  /// Medium tap — hint reveal.
  static void hint() => HapticFeedback.mediumImpact();

  /// Selection feedback.
  static void select() => HapticFeedback.selectionClick();

  /// Undo action.
  static void undo() => HapticFeedback.selectionClick();

  /// Erase action.
  static void erase() => HapticFeedback.selectionClick();

  /// Puzzle complete — crescendo of 3 taps.
  static Future<void> complete() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 100));
    HapticFeedback.heavyImpact();
  }

  /// UI button tap.
  static void tap() => HapticFeedback.lightImpact();
}

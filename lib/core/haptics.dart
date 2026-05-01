import 'package:flutter/services.dart';

/// Centralized haptic feedback with distinct patterns for game events.
class Haptics {
  Haptics._();

  static void correctPlacement() => HapticFeedback.lightImpact();

  /// Triple thud — communicates a wrong answer clearly.
  static Future<void> mistake() async {
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 55));
    HapticFeedback.mediumImpact();
  }

  static void hint() => HapticFeedback.mediumImpact();

  /// Double tap — signals a row/col/box just completed.
  static Future<void> groupComplete() async {
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 60));
    HapticFeedback.lightImpact();
  }
  static void select() => HapticFeedback.selectionClick();
  static void undo() => HapticFeedback.selectionClick();
  static void erase() => HapticFeedback.selectionClick();
  static void tap() => HapticFeedback.lightImpact();

  /// Celebration burst — escalating then trailing off.
  static Future<void> complete() async {
    HapticFeedback.lightImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 70));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 110));
    HapticFeedback.heavyImpact();
    await Future.delayed(const Duration(milliseconds: 90));
    HapticFeedback.mediumImpact();
    await Future.delayed(const Duration(milliseconds: 120));
    HapticFeedback.lightImpact();
  }
}

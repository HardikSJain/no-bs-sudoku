import 'package:flutter/material.dart';

/// A tap target that a screen reader can actually describe.
///
/// The app is built almost entirely from `GestureDetector` wrapped around
/// `Container`, which is invisible to assistive technology: no role, no name,
/// nothing to activate. This is the one place that gets fixed, so a new
/// screen cannot quietly reintroduce the problem.
///
/// [label] is what the control is called. [hint] is what happens when you
/// activate it, and is only worth setting when that is not obvious from the
/// label.
class Tappable extends StatelessWidget {
  const Tappable({
    super.key,
    required this.label,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.onLongPressEnd,
    this.onLongPressCancel,
    this.hint,
    this.longPressHint,
    this.selected,
    this.behavior = HitTestBehavior.opaque,
  });

  final String label;
  final String? hint;
  final String? longPressHint;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// For hold-to-preview controls, which need to know when the finger lifts
  /// as well as when the press registers.
  final void Function(LongPressEndDetails)? onLongPressEnd;
  final VoidCallback? onLongPressCancel;

  /// Set for controls with an on/off state, so it is announced.
  final bool? selected;

  final HitTestBehavior behavior;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null || onLongPress != null,
      selected: selected,
      label: label,
      hint: hint,
      onTapHint: hint,
      onLongPressHint: longPressHint,
      // The gesture detector below already handles the tap; excluding its
      // descendants stops the label being read out twice.
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        onLongPressEnd: onLongPressEnd,
        onLongPressCancel: onLongPressCancel,
        behavior: behavior,
        child: child,
      ),
    );
  }
}

/// How the app treats the system text-size setting.
///
/// Sudoku has one hard constraint the rest of the UI does not: the board is a
/// nine-by-nine grid that must stay square and fit the width, so its digits
/// cannot grow without the cells growing, and the cells cannot grow. Every
/// other surface scales normally.
class TextScale {
  const TextScale._();

  /// The board. Clamped, because a 2x digit in a 39dp cell is unreadable in a
  /// different way from a small one — it is clipped.
  static const double boardMax = 1.3;

  /// Everything else. Generous, and the layouts are tested at it.
  static const double contentMax = 2.0;

  static TextScaler clampFor(BuildContext context, double max) =>
      TextScaler.linear(
        MediaQuery.textScalerOf(context).scale(1).clamp(1.0, max),
      );
}

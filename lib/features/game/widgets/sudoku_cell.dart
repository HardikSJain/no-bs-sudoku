import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class SudokuCell extends StatefulWidget {
  final int value;
  final Set<int> notes;
  final bool isGiven;
  final bool isSelected;
  final bool isSameNumber;
  final bool isRelated;
  final bool isConflict;
  final bool isEvenBox;
  final bool isGroupJustComplete;

  /// The cell a hint is pointing at, from the narrow rung on.
  final bool isHintTarget;

  /// A cell that proves the current hint, from the explain rung on. Shown
  /// differently from the target: these are the evidence, not the answer.
  final bool isHintWitness;

  final VoidCallback onTap;

  const SudokuCell({
    super.key,
    required this.value,
    required this.notes,
    required this.isGiven,
    required this.isSelected,
    required this.isSameNumber,
    required this.isRelated,
    required this.isConflict,
    required this.isEvenBox,
    this.isGroupJustComplete = false,
    this.isHintTarget = false,
    this.isHintWitness = false,
    required this.onTap,
  });

  @override
  State<SudokuCell> createState() => _SudokuCellState();
}

class _SudokuCellState extends State<SudokuCell>
    with TickerProviderStateMixin {
  late final AnimationController _flashCtrl;   // correct placement: bell-curve mint bloom
  late final AnimationController _groupCtrl;   // group completion: slower bloom
  int _prevValue = 0;

  @override
  void initState() {
    super.initState();
    _prevValue = widget.value;
    _flashCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _groupCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
  }

  @override
  void dispose() {
    _flashCtrl.dispose();
    _groupCtrl.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant SudokuCell old) {
    super.didUpdateWidget(old);
    final newVal = widget.value;
    // Correct placement bloom
    if (newVal != _prevValue && newVal != 0 && !widget.isGiven && !widget.isConflict) {
      _flashCtrl.forward(from: 0);
    }
    // Group completion bloom
    if (widget.isGroupJustComplete && !old.isGroupJustComplete) {
      _groupCtrl.forward(from: 0);
    }
    _prevValue = newVal;
  }

  Color _backgroundColor(AppThemeColors col) {
    if (widget.isConflict) return col.error.withValues(alpha: 0.18);
    // The hint outranks selection: while an explanation is on screen, what
    // it is pointing at is what you need to see.
    if (widget.isHintTarget) return col.sun;
    if (widget.isSelected) return col.accent;
    if (widget.isHintWitness) {
      return col.sun.withValues(alpha: col.isLight ? 0.35 : 0.18);
    }
    if (widget.isSameNumber) return col.sun.withValues(alpha: col.isLight ? 0.85 : 0.2);
    if (widget.isRelated) return col.background;
    return widget.isEvenBox ? col.paper : col.background2;
  }

  BoxDecoration _decoration(AppThemeColors col, Color bg) {
    if (widget.isConflict) {
      return BoxDecoration(color: bg);
    }
    if (widget.isHintTarget) {
      return BoxDecoration(
        color: bg,
        boxShadow: [
          BoxShadow(
            color: col.ink,
            spreadRadius: -1,
            blurRadius: 0,
            offset: Offset.zero,
          ),
        ],
      );
    }
    if (widget.isSelected) {
      return BoxDecoration(
        color: bg,
        boxShadow: [BoxShadow(color: col.ink, spreadRadius: -1, blurRadius: 0, offset: Offset.zero)],
      );
    }
    return BoxDecoration(color: bg);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final normalBg = _backgroundColor(col);

    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_flashCtrl, _groupCtrl]),
        builder: (context, child) {
          Color bg = normalBg;
          // Bell-curve bloom: sin(π·t) peaks at midpoint, gentle ramp in and out
          if (_flashCtrl.isAnimating || _flashCtrl.value > 0 && _flashCtrl.value < 1) {
            final intensity = sin(pi * _flashCtrl.value).clamp(0.0, 1.0);
            bg = Color.lerp(normalBg, col.mint.withValues(alpha: 0.45), intensity) ?? normalBg;
          }
          if (_groupCtrl.isAnimating || _groupCtrl.value > 0 && _groupCtrl.value < 1) {
            final intensity = sin(pi * _groupCtrl.value).clamp(0.0, 1.0);
            final groupBg = Color.lerp(normalBg, col.mint.withValues(alpha: 0.55), intensity) ?? normalBg;
            bg = Color.lerp(bg, groupBg, intensity) ?? bg;
          }
          return Container(
            decoration: _decoration(col, bg),
            child: child,
          );
        },
        child: Center(
          child: widget.value != 0 ? _buildValue(col) : _buildNotes(col),
        ),
      ),
    );
  }

  Widget _buildValue(AppThemeColors col) {
    final Color color;
    if (widget.isConflict) {
      color = col.error;
    } else if (widget.isSelected) {
      color = Colors.white;
    } else if (widget.isGiven) {
      color = col.ink;
    } else {
      color = col.accent;
    }

    final text = Text(
      '${widget.value}',
      style: AppTypography.number.copyWith(
        color: color,
        fontWeight: widget.isGiven ? FontWeight.w400 : FontWeight.w500,
      ),
    );

    if (!widget.isGiven && !widget.isConflict && !widget.isSelected) {
      return text
          .animate(key: ValueKey(widget.value))
          .scale(
            begin: const Offset(0.88, 0.88),
            end: const Offset(1, 1),
            duration: 200.ms,
            curve: Curves.easeOutCubic,
          )
          .fadeIn(duration: 150.ms);
    }

    if (widget.isConflict) {
      return text
          .animate(key: ValueKey('conflict_${widget.value}'))
          .shakeX(hz: 5, amount: 2.5, duration: 250.ms);
    }

    return text;
  }

  Widget _buildNotes(AppThemeColors col) {
    if (widget.notes.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.all(1),
      child: GridView.count(
        crossAxisCount: 3,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        children: List.generate(9, (i) {
          final n = i + 1;
          return Center(
            child: Text(
              widget.notes.contains(n) ? '$n' : '',
              style: AppTypography.numberSmall.copyWith(
                color: col.ink3,
                fontSize: 7,
              ),
            ),
          );
        }),
      ),
    );
  }
}

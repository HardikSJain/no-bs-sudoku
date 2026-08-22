import 'dart:math';

import 'package:flutter/foundation.dart';
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

  /// Zero-based position, for the screen-reader label. Without it the board
  /// reads as eighty-one identical buttons.
  final int row;
  final int col;
  final bool isGroupJustComplete;

  /// Part of the unit a hint has named. The weakest of the three hint
  /// states — it says "look here", not "this one".
  final bool isHintUnit;

  /// An empty cell where the previewed digit could still go.
  final bool isPreviewSpot;

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
    required this.row,
    required this.col,
    this.isGroupJustComplete = false,
    this.isHintUnit = false,
    this.isPreviewSpot = false,
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
    if (widget.isPreviewSpot) {
      return col.mint.withValues(alpha: col.isLight ? 0.55 : 0.22);
    }
    if (widget.isHintWitness) {
      return col.sun.withValues(alpha: col.isLight ? 0.35 : 0.18);
    }
    // Deliberately fainter than a witness: the escalation should read as
    // shade the area, point at the cell, light the evidence, fill it in.
    if (widget.isHintUnit) {
      return col.sun.withValues(alpha: col.isLight ? 0.16 : 0.08);
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

  /// What a screen reader says for this cell.
  ///
  /// Position first, because without it the board is eighty-one unlabelled
  /// buttons. Then the contents, then only the states that change what the
  /// player can do about it.
  String get _semanticLabel {
    final parts = <String>[
      'row ${widget.row + 1}, column ${widget.col + 1}',
      if (widget.value != 0)
        '${widget.value}${widget.isGiven ? ', given' : ''}'
      else if (widget.notes.isEmpty)
        'empty'
      else
        'notes ${(widget.notes.toList()..sort()).join(', ')}',
      if (widget.isConflict) 'wrong',
      if (widget.isHintTarget) 'the hint points here',
      if (widget.isHintWitness) 'part of the hint',
    ];
    return parts.join(', ');
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final normalBg = _backgroundColor(col);

    return Semantics(
      label: _semanticLabel,
      selected: widget.isSelected,
      button: !widget.isGiven,
      enabled: !widget.isGiven,
      excludeSemantics: true,
      child: _buildCell(col, normalBg),
    );
  }

  Widget _buildCell(AppThemeColors col, Color normalBg) {
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

    // Painted, not laid out. This used to be a shrink-wrapping GridView plus
    // nine Text widgets per empty cell — on a fully pencilled grid that is
    // sixty grid views and five hundred and forty text widgets, rebuilt on
    // every hint tap and every placement. Technique drills arrive with the
    // notes already seeded, so that is now the normal case rather than the
    // rare one.
    return Padding(
      padding: const EdgeInsets.all(1),
      child: CustomPaint(
        painter: _NotesPainter(notes: widget.notes, color: col.ink3),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Draws the pencil marks directly.
class _NotesPainter extends CustomPainter {
  _NotesPainter({required this.notes, required this.color});

  final Set<int> notes;
  final Color color;

  /// Laying out a TextPainter is the expensive part, and there are only ever
  /// nine glyphs at one size and colour. Cached across every cell in the
  /// grid rather than rebuilt per cell per paint.
  static final Map<(Color, int), TextPainter> _glyphs = {};

  static TextPainter _glyph(Color color, int digit) =>
      _glyphs.putIfAbsent((color, digit), () {
        final tp = TextPainter(
          text: TextSpan(
            text: '$digit',
            style: AppTypography.numberSmall.copyWith(
              color: color,
              fontSize: 7,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        return tp;
      });

  @override
  void paint(Canvas canvas, Size size) {
    final cw = size.width / 3;
    final ch = size.height / 3;
    for (final digit in notes) {
      if (digit < 1 || digit > 9) continue;
      final i = digit - 1;
      final tp = _glyph(color, digit);
      tp.paint(
        canvas,
        Offset(
          (i % 3) * cw + (cw - tp.width) / 2,
          (i ~/ 3) * ch + (ch - tp.height) / 2,
        ),
      );
    }
  }

  @override
  bool shouldRepaint(_NotesPainter old) =>
      old.color != color || !setEquals(old.notes, notes);
}

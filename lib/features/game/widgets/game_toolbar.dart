import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/a11y/tappable.dart';
import '../../../core/haptics.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';
import '../hint_engine.dart';

class GameToolbar extends StatelessWidget {
  const GameToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.history.length != curr.history.length ||
          prev.isNotesMode != curr.isNotesMode ||
          prev.hintRung != curr.hintRung ||
          prev.hasHint != curr.hasHint ||
          prev.hintWasUnprompted != curr.hintWasUnprompted,
      builder: (context, state) {
        final cubit = context.read<GameCubit>();
        final col = context.appColors;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              _ToolCard(
                icon: const _UndoIcon(),
                label: 'undo',
                col: col,
                enabled: state.history.isNotEmpty,
                onTap: state.history.isEmpty
                    ? null
                    : () { Haptics.undo(); cubit.undo(); },
              ),
              _ToolCard(
                icon: const _EraseIcon(),
                label: 'erase',
                col: col,
                enabled: true,
                onTap: () {
                  if (cubit.erase()) Haptics.erase();
                },
              ),
              _ToolCard(
                icon: const _NotesIcon(),
                label: 'notes',
                col: col,
                enabled: true,
                isActive: state.isNotesMode,
                activeColor: col.mint,
                onTap: () { Haptics.select(); cubit.toggleNotesMode(); },
                onLongPress: () { Haptics.select(); cubit.autoFillNotes(); },
                longPressLabel: 'auto-fill',
              ),
              _ToolCard(
                icon: const _HintIcon(),
                // Mid-explanation the button is how you ask for more, so it
                // says so. There is no counter any more: hints are unlimited
                // and cost quality by how deep you push them, so a badge
                // counting down would be describing a rule that no longer
                // exists.
                // The last rung fills the cell in, so it says so.
                //
                // The plan called for a confirmation before that step. A
                // dialog is the wrong tool: the player has already tapped
                // three times deliberately, and a modal to confirm a
                // deliberate tap is friction. The regret case is narrower —
                // tapping "more" out of habit at the explain rung and getting
                // the answer instead of more explanation — and relabelling
                // removes it without an extra tap.
                label: !state.hasHint
                    ? 'hint'
                    : state.hintRung == HintRung.explain
                        ? 'show me'
                        : state.hintRung.isLast
                            ? 'hint'
                            : 'more',
                semanticHint: !state.hasHint
                    ? 'get a hint'
                    : state.hintRung == HintRung.explain
                        ? 'fill this one in for me'
                        : 'explain the current hint further',
                pulse: state.hintWasUnprompted,
                col: col,
                enabled: true,
                activeColor: col.sun,
                isActive: true,
                // The haptic fires after the call, never before it: it used
                // to buzz to confirm a tap that then did nothing. Platform
                // calls stay out of the cubit so it remains testable without
                // a Flutter binding.
                onTap: () {
                  final result = cubit.useHint();
                  if (result is HintNothing) {
                    Haptics.select();
                  } else {
                    // A different feel per rung, so escalation is legible
                    // without looking away from the board.
                    unawaited(Haptics.hintRung(cubit.state.hintRung.index));
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ToolCard extends StatelessWidget {
  final Widget icon;
  final String label;
  final AppThemeColors col;
  final bool enabled;
  final bool isActive;
  final Color? activeColor;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? longPressLabel;

  /// Draws attention without taking the screen. Only ever set for a nudge the
  /// player did not ask for.
  final bool pulse;

  /// What activating it does, when the label alone does not say. Read out
  /// after the label by a screen reader.
  final String? semanticHint;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.col,
    required this.enabled,
    this.isActive = false,
    this.activeColor,
    this.onTap,
    this.onLongPress,
    this.longPressLabel,
    this.pulse = false,
    this.semanticHint,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive && activeColor != null ? activeColor! : col.paper;
    final iconColor = enabled ? col.ink : col.ink4;

    return Expanded(
      child: _maybePulse(Tappable(
        label: label,
        hint: semanticHint,
        longPressHint: longPressLabel,
        selected: isActive ? true : null,
        onTap: onTap,
        onLongPress: onLongPress,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: enabled ? bg : col.background2,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: enabled ? col.ink : col.ink4,
                      width: 2,
                    ),
                    boxShadow: enabled
                        ? [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)]
                        : [],
                  ),
                  child: Center(
                    child: IconTheme(
                      data: IconThemeData(color: iconColor, size: 20),
                      child: icon,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: enabled ? col.ink3 : col.ink4,
                fontSize: 9,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
            ),
            // Long-press actions are invisible without a hint. This label was
            // declared and passed but never rendered, which is why auto-fill
            // notes was undiscoverable.
            if (longPressLabel != null && enabled)
              Text(
                'hold: $longPressLabel',
                style: AppTypography.labelSmall.copyWith(
                  color: col.ink4,
                  fontSize: 7,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
      )),
    );
  }

  /// A slow breath, only for help the player did not ask for.
  ///
  /// An unprompted nudge has to be noticeable without a modal, a toast, or
  /// anything else that takes the screen away mid-thought — the whole point
  /// is that someone deep in a puzzle can ignore it.
  Widget _maybePulse(Widget child) {
    if (!pulse) return child;
    return child
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 1, end: 1.05, duration: 700.ms, curve: Curves.easeInOut);
  }
}

class _UndoIcon extends StatelessWidget {
  const _UndoIcon();
  @override
  Widget build(BuildContext context) {
    final color = IconTheme.of(context).color ?? Colors.black;
    return CustomPaint(size: const Size(20, 20), painter: _UndoIconPainter(color));
  }
}

class _UndoIconPainter extends CustomPainter {
  final Color color;
  _UndoIconPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = color
      ..strokeWidth = 1.6
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final path = Path()
      ..moveTo(4, 8)
      ..lineTo(12, 8)
      ..arcToPoint(const Offset(16, 12), radius: const Radius.circular(4), clockwise: true)
      ..arcToPoint(const Offset(12, 16), radius: const Radius.circular(4), clockwise: true)
      ..lineTo(8, 16);
    canvas.drawPath(path, p);
    canvas.drawLine(const Offset(4, 5), const Offset(4, 11), p);
    canvas.drawLine(const Offset(1, 8), const Offset(4, 5), p);
    canvas.drawLine(const Offset(7, 8), const Offset(4, 5), p);
  }

  @override
  bool shouldRepaint(_UndoIconPainter old) => old.color != color;
}

class _EraseIcon extends StatelessWidget {
  const _EraseIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.backspace_outlined, color: IconTheme.of(context).color, size: 20);
  }
}

class _NotesIcon extends StatelessWidget {
  const _NotesIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.edit_outlined, color: IconTheme.of(context).color, size: 20);
  }
}

class _HintIcon extends StatelessWidget {
  const _HintIcon();
  @override
  Widget build(BuildContext context) {
    return Icon(Icons.lightbulb_outline_rounded, color: IconTheme.of(context).color, size: 20);
  }
}

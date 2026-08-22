import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/haptics.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';

class GameToolbar extends StatelessWidget {
  const GameToolbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.history.length != curr.history.length ||
          prev.isNotesMode != curr.isNotesMode ||
          prev.hintsRemaining != curr.hintsRemaining,
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
                label: 'hint',
                col: col,
                enabled: state.hintsRemaining > 0,
                activeColor: col.sun,
                isActive: state.hintsRemaining > 0,
                badge: state.hintsRemaining > 0 ? '${state.hintsRemaining}' : null,
                // Haptic fires only on a spent hint. It used to fire before
                // the call, so an unusable tap buzzed to confirm and then did
                // nothing.
                onTap: state.hintsRemaining > 0
                    ? () {
                        if (cubit.useHint()) {
                          Haptics.hint();
                        } else {
                          Haptics.select();
                        }
                      }
                    : null,
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
  final String? badge;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final String? longPressLabel;

  const _ToolCard({
    required this.icon,
    required this.label,
    required this.col,
    required this.enabled,
    this.isActive = false,
    this.activeColor,
    this.badge,
    this.onTap,
    this.onLongPress,
    this.longPressLabel,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isActive && activeColor != null ? activeColor! : col.paper;
    final iconColor = enabled ? col.ink : col.ink4;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        onLongPress: onLongPress,
        behavior: HitTestBehavior.opaque,
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
                if (badge != null)
                  Positioned(
                    top: -6,
                    right: -6,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      decoration: BoxDecoration(
                        color: col.error,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(color: col.ink, width: 1.5),
                      ),
                      child: Center(
                        child: Text(
                          badge!,
                          style: AppTypography.labelSmall.copyWith(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
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
      ),
    );
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

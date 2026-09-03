import 'package:flutter/material.dart';

import '../../../core/a11y/tappable.dart';
import '../../../core/duration_format.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/storage/app_database.dart';
import '../../../engine/sudoku_solver.dart';
import '../../../core/haptics.dart';

class DailyPuzzleCard extends StatelessWidget {
  final bool completed;
  final int? timeSeconds;
  final Difficulty difficulty;
  final int puzzleNum;
  final VoidCallback? onTap;
  final SavedGame? inProgressGame;

  const DailyPuzzleCard({
    super.key,
    required this.completed,
    this.timeSeconds,
    required this.difficulty,
    required this.puzzleNum,
    this.onTap,
    this.inProgressGame,
  });

  double _computeProgress(SavedGame saved) {
    final puzzle = saved.givenCells.split(',').map(int.parse).toList();
    final board = saved.boardCells.split(',').map(int.parse).toList();
    int totalEmpty = 0;
    int filled = 0;
    for (int i = 0; i < 81; i++) {
      if (puzzle[i] == 0) {
        totalEmpty++;
        if (board[i] != 0) filled++;
      }
    }
    if (totalEmpty == 0) return 1.0;
    return filled / totalEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat('MMM d').format(DateTime.now()).toUpperCase();
    final col = context.appColors;

    final isInProgress = inProgressGame != null && !completed;
    final progress = isInProgress ? _computeProgress(inProgressGame!) : (completed ? 1.0 : 0.0);
    final pct = (progress * 100).round();

    final elapsed = isInProgress ? inProgressGame!.elapsedSeconds : (timeSeconds ?? 0);
    final timeStr = clockTime(elapsed);

    return Tappable(
      label: [
        "today's puzzle, ${difficulty.name}",
        if (completed)
          'completed in ${spokenDuration(timeSeconds ?? 0)}'
        else if (inProgressGame != null)
          'in progress, ${spokenDuration(inProgressGame!.elapsedSeconds)} in'
        else
          'not played yet',
      ].join('. '),
      hint: completed
          ? 'review it'
          : inProgressGame != null
              ? 'carry on'
              : 'start it',
      onTap: () {
        Haptics.tap();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: col.accent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'DAILY · $today',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "today's puzzle",
                        style: AppTypography.wordmark.copyWith(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                // Difficulty sticker
                Transform.rotate(
                  angle: 0.04,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: col.sun,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: col.ink, width: 1.5),
                      boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
                    ),
                    child: Text(
                      difficulty.name.toUpperCase(),
                      style: AppTypography.labelSmall.copyWith(
                        color: col.ink,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Time + pct
            if (isInProgress || completed)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Text(
                      timeStr,
                      style: AppTypography.number.copyWith(
                        color: col.sun,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (isInProgress) ...[
                      Text(
                        '  ·  $pct% there',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ] else if (completed) ...[
                      Text(
                        '  ·  completed',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            // Progress bar, only once there is progress to draw.
            //
            // An empty track on a puzzle nobody has opened is a widget
            // describing nothing: the fill is zero-width, so all that renders
            // is a faint hairline against the cobalt, which reads as a smudge
            // at the card's left edge. The "not played yet" line below already
            // says the same thing, in words.
            if (progress > 0) ...[
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: col.ink.withValues(alpha: 0.3), width: 1),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: progress.clamp(0.0, 1.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: col.sun,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            // Bottom: status or resume button
            if (isInProgress)
              _ResumeButton(col: col)
            else if (!completed)
              Text(
                'not played yet',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 11,
                ),
              )
            else
              Row(
                children: [
                  const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 14),
                  const SizedBox(width: 5),
                  Text(
                    'done',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class _ResumeButton extends StatelessWidget {
  final AppThemeColors col;
  const _ResumeButton({required this.col});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: col.sun,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.ink, width: 1.5),
        boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'RESUME',
            style: AppTypography.labelSmall.copyWith(
              color: col.ink,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.arrow_forward_rounded, color: col.ink, size: 13),
        ],
      ),
    );
  }
}

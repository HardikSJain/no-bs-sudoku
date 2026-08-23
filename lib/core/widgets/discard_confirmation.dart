import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../a11y/tappable.dart';
import '../daily_key.dart';
import '../storage/app_database.dart';
import '../theme/app_theme_colors.dart';
import '../theme/app_typography.dart';

/// Asks before throwing away a puzzle in progress. Returns true to proceed.
///
/// Every start path used to call `deleteSavedGame()` unconditionally, with the
/// resume bar for that very game rendered directly above the buttons. One
/// mistap silently destroyed an in-progress puzzle.
///
/// Shared rather than private to the home screen because the archive can
/// start a puzzle too, and two copies of a confirmation is how one of them
/// ends up missing.
Future<bool> confirmDiscard(BuildContext context, SavedGame? saved) async {
  if (saved == null) return true;

  final col = context.appColors;
  final proceed = await showModalBottomSheet<bool>(
    context: context,
    backgroundColor: col.paper,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (ctx) => Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'you have ${_describe(saved)} in progress.',
            style: AppTypography.body.copyWith(color: col.ink),
          ),
          const SizedBox(height: 4),
          Text(
            'starting a new one discards it.',
            style: AppTypography.labelSmall.copyWith(color: col.ink3),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Tappable(
                  label: 'keep it',
                  hint: 'go back and carry on with the puzzle in progress',
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: col.paper,
                      border: Border.all(color: col.ink, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: col.cardShadow,
                    ),
                    child: Center(
                      child: Text('keep it',
                          style:
                              AppTypography.button.copyWith(color: col.ink)),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Tappable(
                  label: 'discard',
                  hint: 'throw away the puzzle in progress and start a new one',
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: col.error,
                      border: Border.all(color: col.ink, width: 2),
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: col.cardShadow,
                    ),
                    child: Center(
                      child: Text('discard',
                          style: AppTypography.button
                              .copyWith(color: Colors.white)),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
  return proceed ?? false;
}

/// What to call the game about to be thrown away.
///
/// It used to be "a ${difficulty} puzzle" for everything, which produced "a
/// expert puzzle" and told a player nothing about *which* puzzle — the
/// difficulty is the least surprising thing about the daily.
String _describe(SavedGame saved) {
  if (saved.isDaily) {
    final date = parseDailyPuzzleId(saved.puzzleId);
    if (date == null || date == todayUtc()) return "today's daily";
    return 'the daily from ${DateFormat('d MMMM').format(date).toLowerCase()}';
  }
  return '${_article(saved.difficulty)} ${saved.difficulty} puzzle';
}

String _article(String word) =>
    'aeiou'.contains(word.isEmpty ? 'x' : word[0]) ? 'an' : 'a';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../a11y/tappable.dart';
import '../daily_key.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../storage/app_database.dart';
import '../storage/repositories/repositories.dart';
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
Future<bool> confirmDiscard(
  BuildContext context,
  SavedGame? saved, {
  String reason = 'starting a new one discards it.',
}) async {
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
            'you have ${describeSavedGame(saved)} in progress.',
            style: AppTypography.body.copyWith(color: col.ink),
          ),
          const SizedBox(height: 4),
          Text(
            reason,
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

/// What to call the game about to be thrown away, in prose.
///
/// It used to be "a ${difficulty} puzzle" for everything, which produced "a
/// expert puzzle" and told a player nothing about *which* puzzle — the
/// difficulty is the least surprising thing about the daily.
///
/// Public because the button that opens this sheet has to say the same thing
/// the sheet then says, and a screen reader announcing "discard hard" is not
/// a sentence.
String describeSavedGame(SavedGame saved) {
  if (saved.isDaily) {
    final date = parseDailyPuzzleId(saved.puzzleId);
    if (date == null || date == todayUtc()) return "today's daily";
    return 'the daily from ${DateFormat('d MMMM').format(date).toLowerCase()}';
  }
  return '${_article(saved.difficulty)} ${saved.difficulty} puzzle';
}

String _article(String word) =>
    'aeiou'.contains(word.isEmpty ? 'x' : word[0]) ? 'an' : 'a';

/// Asks about whatever non-daily game is in progress, if any.
///
/// The start paths do not all have a cubit holding the saved games, so this
/// reads them. [confirmDiscard] was written to be shared and its own comment
/// says why — and then the tier pages and the importer were added and never
/// called it, so starting a fish puzzle or playing an imported grid quietly
/// destroyed whatever was half-finished. One entry point, so the next start
/// path gets it by reaching for the obvious thing.
Future<bool> confirmDiscardSavedGame(
  BuildContext context, {
  required bool isDaily,
}) async {
  final saved = await context.read<SavedGameRepository>().getSavedGames();
  if (!context.mounted) return false;
  return confirmDiscard(context, saved.slotFor(isDaily: isDaily));
}

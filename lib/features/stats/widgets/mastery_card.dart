import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/a11y/tappable.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../engine/deduction/deduction.dart';
import '../../game/technique_copy.dart';
import '../../learn/mastery.dart';

/// Technique mastery, on the screen people actually check for progress.
///
/// The library is where mastery lives, and a player who has not gone looking
/// for it has no idea it exists. Times and streaks are one kind of progress;
/// knowing more of the game is the other, and it belongs next to them.
class MasteryCard extends StatelessWidget {
  const MasteryCard({super.key, required this.profile});

  final MasteryProfile profile;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final done = profile.masteredCount;
    final total = profile.drillableCount;
    final next = profile.suggested;

    return Tappable(
      label: 'techniques, $done of $total mastered'
          '${next == null ? '' : '. next up ${next.singular}'}',
      hint: 'open the technique library',
      onTap: () => context.push('/learn'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: col.outline, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // The heading yields before the count does. At a large text
                // size the two of them stop fitting side by side, and of the
                // pair it is the count that carries information — the heading
                // is a label for something the pips below already show.
                Flexible(
                  child: Text('TECHNIQUES',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.labelSmall.copyWith(
                          color: col.ink3,
                          fontSize: 10,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 8),
                Text('$done of $total',
                    maxLines: 1,
                    style: AppTypography.number.copyWith(
                        color: col.ink,
                        fontSize: 13,
                        fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            // One pip per technique, filled by how well it is known. Reads at
            // a glance as ground covered, which a single number does not.
            _Pips(profile: profile, col: col),
            const SizedBox(height: 12),
            Text(
              next == null
                  ? 'every technique mastered. nothing left to teach you.'
                  : 'next up: ${next.singular}. ${profile[next].nextStep ?? ''}',
              style: AppTypography.labelSmall
                  .copyWith(color: col.ink3, fontSize: 11, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class _Pips extends StatelessWidget {
  const _Pips({required this.profile, required this.col});

  final MasteryProfile profile;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    final drillable = [
      for (final t in Technique.values)
        if (t.isDrillable) t,
    ]..sort((a, b) => a.rank.compareTo(b.rank));

    return Row(
      children: [
        for (final t in drillable) ...[
          Expanded(
            child: Container(
              height: 6,
              decoration: BoxDecoration(
                color: switch (profile[t].level) {
                  MasteryLevel.mastered => col.accent,
                  MasteryLevel.practised => col.mint,
                  MasteryLevel.learning => col.sun,
                  MasteryLevel.seen => col.ink4.withValues(alpha: 0.45),
                  MasteryLevel.unseen => col.ink4.withValues(alpha: 0.2),
                },
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          if (t != drillable.last) const SizedBox(width: 3),
        ],
      ],
    );
  }
}

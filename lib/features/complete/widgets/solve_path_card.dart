import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../engine/deduction/deduction.dart';
import '../../../engine/deduction/solve_path_analysis.dart';
import '../../game/technique_copy.dart';

/// The puzzle's logical skeleton: what it took, and where the work was.
///
/// Off by default and never shown unbidden. A post-solve technique debrief
/// reads as an interruption to most players, which is why it is opt-in — but
/// for the audience that wants it, this is the payoff.
class SolvePathCard extends StatelessWidget {
  const SolvePathCard({super.key, required this.analysis});

  final SolvePathAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    if (analysis.totalSteps == 0) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'HOW IT WAS BUILT',
            style: AppTypography.labelSmall.copyWith(
              color: col.ink3,
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _summary(),
            style: AppTypography.body
                .copyWith(color: col.ink, fontSize: 12, height: 1.4),
          ),
          const SizedBox(height: 12),
          _TierBand(analysis: analysis, col: col),
          const SizedBox(height: 12),
          for (final use in analysis.uses) ...[
            _UseRow(use: use, total: analysis.totalSteps, col: col),
            const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  String _summary() {
    final hardest = analysis.hardest;
    if (hardest == null) return '${analysis.totalSteps} steps.';

    final at = analysis.hardestAt;
    // Where the difficulty sat matters more than that it existed: a puzzle
    // that turns at step 40 of 50 feels nothing like one that turns at 5.
    final when = at == null
        ? ''
        : at < 0.33
            ? ' it turned early.'
            : at > 0.66
                ? ' it held out until near the end.'
                : ' it turned about halfway.';

    return '${analysis.totalSteps} steps, and the hardest was a '
        '${hardest.singular}.$when';
  }
}

/// The solve's profile over time — one stripe per step, coloured by tier.
///
/// Makes "easy until step 40" visible at a glance, which is the thing a
/// list of counts cannot show.
class _TierBand extends StatelessWidget {
  const _TierBand({required this.analysis, required this.col});

  final SolvePathAnalysis analysis;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: SizedBox(
        height: 10,
        child: Row(
          children: [
            for (final tier in analysis.tierByStep)
              Expanded(child: ColoredBox(color: _tierColor(tier))),
          ],
        ),
      ),
    );
  }

  Color _tierColor(TechniqueTier tier) => switch (tier) {
        TechniqueTier.singles => col.ink4.withValues(alpha: 0.25),
        TechniqueTier.pairs => col.mint,
        TechniqueTier.intersections => col.sun,
        TechniqueTier.fish => col.accent,
        TechniqueTier.chains => col.error,
      };
}

class _UseRow extends StatelessWidget {
  const _UseRow({required this.use, required this.total, required this.col});

  final TechniqueUse use;
  final int total;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            use.technique.plural,
            style: AppTypography.labelSmall
                .copyWith(color: col.ink3, fontSize: 11),
          ),
        ),
        Text(
          '${use.count}',
          style: AppTypography.number.copyWith(
            color: col.ink,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

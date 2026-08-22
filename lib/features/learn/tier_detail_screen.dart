import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/a11y/tappable.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_back_button.dart';
import '../../engine/deduction/deduction.dart';
import '../../engine/sudoku_solver.dart';
import '../game/technique_copy.dart';
import 'learn_cubit.dart';
import 'learn_screen.dart';
import 'mastery.dart';
import 'technique_guide.dart';
import 'widgets/pattern_diagram.dart';

/// What a whole tier is, before you commit to a puzzle that needs it.
///
/// The deep tiers are named with words most people have never met — "fish"
/// means nothing until somebody shows you one. Tapping the card on home used
/// to spend several seconds generating a puzzle that required a technique the
/// player had no way to look up from there. Now it explains first and offers
/// the puzzle at the bottom, which is the only sensible order for something
/// unfamiliar.
class TierDetailScreen extends StatelessWidget {
  const TierDetailScreen({super.key, required this.tier, this.difficulty});

  final TechniqueTier tier;

  /// Set when this tier is playable as a difficulty of its own.
  final Difficulty? difficulty;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final techniques =
        Technique.values.where((t) => t.tier == tier).toList();

    return BlocBuilder<LearnCubit, LearnState>(
      builder: (context, state) {
        final profile = state.profile ?? const MasteryProfile({});

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 20),
                    children: [
                      const Row(children: [AppBackButton()]),
                      const SizedBox(height: 6),
                      Text('${tier.plainName}.',
                          style:
                              AppTypography.heading.copyWith(color: col.ink)),
                      const SizedBox(height: 8),
                      Text(
                        tier.explainer,
                        style: AppTypography.body.copyWith(
                            color: col.ink, fontSize: 13.5, height: 1.5),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        techniques.length == 1
                            ? 'THE TECHNIQUE'
                            : 'THE ${techniques.length} TECHNIQUES',
                        style: AppTypography.labelSmall.copyWith(
                            color: col.ink3,
                            fontSize: 9,
                            letterSpacing: 1.2,
                            fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      for (final technique in techniques) ...[
                        _TechniqueCard(
                          technique: technique,
                          mastery: profile[technique],
                        ),
                        const SizedBox(height: 10),
                      ],
                    ],
                  ),
                ),
                if (difficulty case final d?) _PlayButton(difficulty: d),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// A technique shown at a glance: the shape, the one-liner, the cue.
///
/// Enough to recognise it from, with the full page a tap away — someone
/// deciding whether to attempt a fish puzzle needs to see what a fish looks
/// like, not read two screens first.
class _TechniqueCard extends StatelessWidget {
  const _TechniqueCard({required this.technique, required this.mastery});

  final Technique technique;
  final TechniqueMastery mastery;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final guide = TechniqueGuide.of(technique);

    return Tappable(
      label: '${technique.singular}. ${guide.oneLine} '
          'look for: ${guide.lookFor} ${mastery.level.label}',
      hint: 'read about it and practise',
      onTap: () => context.push('/learn/${technique.name}'),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PatternDiagram(
              context_: guide.context,
              witnesses: guide.witnesses,
              targets: guide.targets,
              size: 76,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(technique.singular,
                            style: AppTypography.body.copyWith(
                                color: col.ink,
                                fontWeight: FontWeight.w700,
                                fontSize: 14)),
                      ),
                      const SizedBox(width: 6),
                      MasteryChip(level: mastery.level),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(guide.oneLine,
                      style: AppTypography.labelSmall.copyWith(
                          color: col.ink3, fontSize: 10, height: 1.35)),
                  const SizedBox(height: 6),
                  Text('look for: ${guide.lookFor}',
                      style: AppTypography.labelSmall.copyWith(
                          color: col.ink4, fontSize: 9.5, height: 1.35)),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 180.ms);
  }
}

class _PlayButton extends StatelessWidget {
  const _PlayButton({required this.difficulty});

  final Difficulty difficulty;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Tappable(
        label: 'play a ${difficulty.name} puzzle',
        onTap: () {
          Haptics.tap();
          context.push('/game/${difficulty.name}');
        },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: col.accent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: col.ink, width: 2),
            boxShadow: col.cardShadow,
          ),
          child: Center(
            child: Text('play a ${difficulty.name} puzzle',
                style: AppTypography.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

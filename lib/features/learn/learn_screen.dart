import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../engine/deduction/deduction.dart';
import '../game/technique_copy.dart';
import 'learn_cubit.dart';
import 'mastery.dart';
import 'technique_guide.dart';

/// The technique library: what each one is, and how well you know it.
///
/// One screen rather than two. A list of names to drill and a list of names
/// to read about would be the same list twice, and splitting them is what
/// makes a glossary feel like homework.
class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    return BlocBuilder<LearnCubit, LearnState>(
      builder: (context, state) {
        final profile = state.profile ?? const MasteryProfile({});
        final suggested = profile.suggested;

        return Scaffold(
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.xl),
              children: [
                const Row(children: [AppBackButton()]),
                const SizedBox(height: 6),
                Text('techniques.',
                    style: AppTypography.heading.copyWith(color: col.ink)),
                const SizedBox(height: 6),
                Text(
                  'every way a sudoku can be reasoned out, what each one looks '
                  'like, and how well you know it.',
                  style: AppTypography.body
                      .copyWith(color: col.ink3, fontSize: 12, height: 1.4),
                ),
                const SizedBox(height: 14),
                _ProgressStrip(profile: profile),
                if (suggested != null) ...[
                  const SizedBox(height: 12),
                  _NextUp(technique: suggested, mastery: profile[suggested]),
                ],
                const SizedBox(height: 22),
                for (final tier in TechniqueTier.values) ...[
                  _TierHeader(tier: tier),
                  const SizedBox(height: 8),
                  for (final technique in Technique.values)
                    if (technique.tier == tier) ...[
                      _TechniqueRow(
                        technique: technique,
                        mastery: profile[technique],
                      ),
                      const SizedBox(height: 8),
                    ],
                  const SizedBox(height: 18),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

/// How much of the library is behind you. Counts mastered, not attempted —
/// attempts are effort, and this is meant to measure ground covered.
class _ProgressStrip extends StatelessWidget {
  const _ProgressStrip({required this.profile});

  final MasteryProfile profile;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final done = profile.masteredCount;
    final total = profile.drillableCount;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('mastered',
                  style: AppTypography.labelSmall
                      .copyWith(color: col.ink3, fontSize: 10)),
              const Spacer(),
              Text('$done of $total',
                  style: AppTypography.number.copyWith(
                      color: col.ink, fontSize: 12, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: SizedBox(
              height: 6,
              child: Row(
                children: [
                  if (done > 0)
                    Expanded(flex: done, child: ColoredBox(color: col.accent)),
                  Expanded(
                    flex: total - done,
                    // Strong enough to read as an empty track rather than as
                    // nothing at all — at zero mastered this is the whole bar.
                    child: ColoredBox(
                        color: col.ink4.withValues(alpha: 0.35)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The one thing to do next. A suggestion, never a gate — everything below
/// stays open whatever this says.
class _NextUp extends StatelessWidget {
  const _NextUp({required this.technique, required this.mastery});

  final Technique technique;
  final TechniqueMastery mastery;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return GestureDetector(
      onTap: () => context.push('/learn/${technique.name}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: col.accent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // White on the accent, matching the daily card and the
                  // onboarding CTA. ink3 on this blue is barely legible.
                  Text('NEXT UP',
                      style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 9,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w700)),
                  const SizedBox(height: 3),
                  Text(technique.singular,
                      style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(mastery.nextStep ?? '',
                      style: AppTypography.labelSmall.copyWith(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.white, size: 18),
          ],
        ),
      ),
    );
  }
}

class _TierHeader extends StatelessWidget {
  const _TierHeader({required this.tier});

  final TechniqueTier tier;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(tier.plainName.toUpperCase(),
            style: AppTypography.labelSmall.copyWith(
                color: col.ink3,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.2)),
        const SizedBox(height: 2),
        Text(tier.blurb,
            style: AppTypography.labelSmall
                .copyWith(color: col.ink4, fontSize: 10)),
      ],
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({required this.technique, required this.mastery});

  final Technique technique;
  final TechniqueMastery mastery;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final guide = TechniqueGuide.of(technique);

    return GestureDetector(
      onTap: () => context.push('/learn/${technique.name}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                      const SizedBox(width: 8),
                      MasteryChip(level: mastery.level),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(guide.oneLine,
                      style: AppTypography.labelSmall
                          .copyWith(color: col.ink3, fontSize: 10, height: 1.35)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: col.ink4, size: 16),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 160.ms);
  }
}

/// The level, as a small chip. Colour carries the same information as the
/// word so the list can be skimmed.
class MasteryChip extends StatelessWidget {
  const MasteryChip({super.key, required this.level});

  final MasteryLevel level;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final (bg, fg) = switch (level) {
      MasteryLevel.unseen => (col.ink4.withValues(alpha: 0.15), col.ink4),
      MasteryLevel.seen => (col.ink4.withValues(alpha: 0.25), col.ink3),
      MasteryLevel.learning => (col.sun, col.ink),
      MasteryLevel.practised => (col.mint, col.ink),
      // White on the accent, as everywhere else it is used as a fill.
      MasteryLevel.mastered => (col.accent, Colors.white),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: col.ink, width: 1),
      ),
      child: Text(
        level.label,
        style: AppTypography.labelSmall.copyWith(
          color: fg,
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

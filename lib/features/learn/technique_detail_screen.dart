import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../engine/deduction/deduction.dart';
import '../game/technique_copy.dart';
import 'learn_cubit.dart';
import 'learn_screen.dart';
import 'mastery.dart';
import 'technique_guide.dart';
import 'widgets/pattern_diagram.dart';

/// One technique: what it is, how to spot it, and your record with it.
class TechniqueDetailScreen extends StatelessWidget {
  const TechniqueDetailScreen({super.key, required this.technique});

  final Technique technique;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final guide = TechniqueGuide.of(technique);

    return BlocBuilder<LearnCubit, LearnState>(
      builder: (context, state) {
        final mastery =
            (state.profile ?? const MasteryProfile({}))[technique];

        return Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    // Clears the pinned button, which otherwise crops the
                    // record card.
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, AppSpacing.sm, AppSpacing.md, 20),
                    children: [
                      const Row(children: [AppBackButton()]),
                      const SizedBox(height: 6),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Text(technique.singular,
                                style: AppTypography.heading
                                    .copyWith(color: col.ink)),
                          ),
                          MasteryChip(level: mastery.level),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(guide.oneLine,
                          style: AppTypography.body.copyWith(
                              color: col.ink3, fontSize: 13, height: 1.4)),
                      const SizedBox(height: 18),

                      // The shape, before the words. Several of these are
                      // spatial and one look does more than a paragraph.
                      Center(
                        child: Column(
                          children: [
                            PatternDiagram(
                              context_: guide.context,
                              witnesses: guide.witnesses,
                              targets: guide.targets,
                              size: 168,
                            ),
                            const SizedBox(height: 10),
                            PatternLegend(hasTargets: guide.targets.isNotEmpty),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _Section(
                        label: 'WHAT TO LOOK FOR',
                        body: guide.lookFor,
                        emphasis: true,
                      ),
                      const SizedBox(height: 12),
                      _Section(label: 'WHY IT WORKS', body: guide.how),
                      const SizedBox(height: 12),
                      _RecordCard(mastery: mastery),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
                if (technique.isDrillable)
                  _PractiseButton(technique: technique)
                else
                  _NotDrillableNote(technique: technique),
                const SizedBox(height: AppSpacing.md),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.label,
    required this.body,
    this.emphasis = false,
  });

  final String label;
  final String body;
  final bool emphasis;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        // The recognition cue is the thing worth remembering, so it is the
        // thing that stands out.
        //
        // Blended to an opaque colour rather than laid on at 28% alpha: these
        // cards sit on a hard black drop shadow, and a translucent fill lets
        // that shadow through, which turned a pale yellow into dark olive
        // with unreadable text.
        color: emphasis
            ? Color.alphaBlend(col.sun.withValues(alpha: 0.3), col.surface)
            : col.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTypography.labelSmall.copyWith(
                  color: col.ink3,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(body,
              style: AppTypography.body
                  .copyWith(color: col.ink, fontSize: 12.5, height: 1.5)),
        ],
      ),
    );
  }
}

/// Your record. Shows the raw numbers next to the level, because the level is
/// a summary and someone asking "how good am I" deserves the actual counts.
class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.mastery});

  final TechniqueMastery mastery;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final accuracy = mastery.accuracy;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('YOUR RECORD',
              style: AppTypography.labelSmall.copyWith(
                  color: col.ink3,
                  fontSize: 9,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Row(
            children: [
              _Stat(
                  value: '${mastery.drillsUnaided}',
                  label: 'spotted\nunaided',
                  col: col),
              _Stat(
                  value: '${mastery.drillsAttempted}',
                  label: 'drills\ntried',
                  col: col),
              _Stat(
                  value: '${mastery.encountered}',
                  label: 'met in\npuzzles',
                  col: col),
              _Stat(
                  value: mastery.bestSeconds == null
                      ? '—'
                      : '${mastery.bestSeconds}s',
                  label: 'best\ntime',
                  col: col),
            ],
          ),
          if (accuracy != null) ...[
            const SizedBox(height: 12),
            Text(
              'you spot this unaided ${(accuracy * 100).round()}% of the time.',
              style: AppTypography.labelSmall
                  .copyWith(color: col.ink3, fontSize: 11),
            ),
          ] else if (mastery.drillsAttempted > 0) ...[
            const SizedBox(height: 12),
            Text(
              // Refusing to show a rate here is the honest move, and saying
              // why is better than leaving a blank.
              'a couple of drills is not enough to tell. a few more and a '
              'rate will mean something.',
              style: AppTypography.labelSmall
                  .copyWith(color: col.ink4, fontSize: 10, height: 1.4),
            ),
          ],
          if (mastery.nextStep case final next?) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 5,
                      child: LinearProgressIndicator(
                        value: mastery.progressToNext ?? 0,
                        backgroundColor: col.ink4.withValues(alpha: 0.2),
                        valueColor: AlwaysStoppedAnimation(col.accent),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(next,
                style: AppTypography.labelSmall
                    .copyWith(color: col.ink3, fontSize: 10)),
          ],
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label, required this.col});

  final String value;
  final String label;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value,
              style: AppTypography.number.copyWith(
                  color: col.ink, fontSize: 19, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: col.ink4, fontSize: 8, height: 1.3)),
        ],
      ),
    );
  }
}

class _PractiseButton extends StatelessWidget {
  const _PractiseButton({required this.technique});

  final Technique technique;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: GestureDetector(
        onTap: () {
          Haptics.tap();
          context.push('/train/${technique.name}');
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
            child: Text('practise this',
                style: AppTypography.button.copyWith(color: Colors.white)),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 200.ms);
  }
}

/// Said plainly rather than hidden. A missing button with no explanation
/// reads as a bug.
class _NotDrillableNote extends StatelessWidget {
  const _NotDrillableNote({required this.technique});

  final Technique technique;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Text(
        'no drill for this one. a ${technique.singular} is almost never the '
        'only way forward — a pair usually gets there first — so a puzzle '
        'that truly needs one is vanishingly rare.',
        textAlign: TextAlign.center,
        style: AppTypography.labelSmall
            .copyWith(color: col.ink4, fontSize: 10, height: 1.5),
      ),
    );
  }
}

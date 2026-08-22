import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../engine/deduction/deduction.dart';
import '../game/technique_copy.dart';

/// Pick a technique, get a puzzle built around it.
///
/// The same feature serves a beginner drilling hidden singles and an
/// enthusiast drilling swordfish — one generator, one explanation engine, no
/// watered-down variant for anyone.
class TrainerScreen extends StatelessWidget {
  const TrainerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    // Grouped by tier so the list reads as a progression rather than twelve
    // equally weighted names.
    final byTier = <TechniqueTier, List<Technique>>{};
    for (final t in Technique.values) {
      if (!t.isDrillable) continue;
      byTier.putIfAbsent(t.tier, () => []).add(t);
    }

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, AppSpacing.md, AppSpacing.md, AppSpacing.xl),
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: Icon(Icons.chevron_left, color: col.ink, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('practice.',
                style: AppTypography.heading.copyWith(color: col.ink)),
            const SizedBox(height: 6),
            Text(
              'one move, built around one technique. the position is set up '
              'for you — spot it and place it.',
              style: AppTypography.body
                  .copyWith(color: col.ink3, fontSize: 12, height: 1.4),
            ),
            const SizedBox(height: 22),
            for (final tier in TechniqueTier.values)
              if (byTier[tier] case final techniques?) ...[
                Text(
                  tier.name.toUpperCase(),
                  style: AppTypography.labelSmall.copyWith(
                    color: col.ink3,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                for (final technique in techniques) ...[
                  _TechniqueRow(technique: technique),
                  const SizedBox(height: 8),
                ],
                const SizedBox(height: 14),
              ],
          ].animate(interval: 25.ms).fadeIn(duration: 180.ms),
        ),
      ),
    );
  }
}

class _TechniqueRow extends StatelessWidget {
  const _TechniqueRow({required this.technique});

  final Technique technique;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return GestureDetector(
      onTap: () => context.push('/train/${technique.name}'),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                technique.singular,
                style: AppTypography.body.copyWith(
                  color: col.ink,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: col.ink4, size: 18),
          ],
        ),
      ),
    );
  }
}

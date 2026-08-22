import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/haptics.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../game_cubit.dart';
import '../game_state.dart';
import '../hint_copy.dart';
import '../hint_engine.dart';

/// The explanation, shown between the grid and the toolbar.
///
/// It sits there rather than over the grid on purpose: you are reading the
/// sentence and looking at the cells it describes at the same time, so the
/// board must not be covered, and it must not move or resize either — cells
/// shifting under a finger mid-explanation is worse than the explanation
/// being absent. The toolbar and number pad take the space instead.
class HintPanel extends StatelessWidget {
  const HintPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.activeHint != curr.activeHint ||
          prev.hintRung != curr.hintRung ||
          prev.wrongCells != curr.wrongCells,
      builder: (context, state) {
        if (!state.hasHint) return const SizedBox.shrink();

        final col = context.appColors;
        final cubit = context.read<GameCubit>();
        final result = state.wrongCells.isNotEmpty
            ? HintWrongDigit(state.wrongCells)
            : HintStep(state.activeHint!, honoursSelection: true);
        final label = HintCopy.techniqueLabel(result, state.hintRung);

        return Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
          child: Container(
            width: double.infinity,
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
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (label != null) ...[
                        Text(
                          label.toUpperCase(),
                          style: AppTypography.labelSmall.copyWith(
                            color: col.ink4,
                            fontSize: 9,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                      ],
                      Text(
                        HintCopy.forResult(result, state.hintRung),
                        style: AppTypography.body.copyWith(
                          color: col.ink,
                          fontSize: 13,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 6),
                      _RungDots(rung: state.hintRung, col: col),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Haptics.select();
                    cubit.dismissHint();
                  },
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    // Small glyph, real tap target.
                    padding: const EdgeInsets.only(left: 10, top: 2, bottom: 8),
                    child: Icon(Icons.close, size: 16, color: col.ink4),
                  ),
                ),
              ],
            ),
          ),
        ).animate().fadeIn(duration: 140.ms).slideY(
              begin: 0.15,
              end: 0,
              duration: 160.ms,
              curve: Curves.easeOut,
            );
      },
    );
  }
}

/// How far along the explanation is, and how much further it can go.
class _RungDots extends StatelessWidget {
  const _RungDots({required this.rung, required this.col});

  final HintRung rung;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final r in HintRung.values)
          Container(
            width: r == rung ? 14 : 5,
            height: 5,
            margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: r.index <= rung.index
                  ? col.sun
                  : col.ink4.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
      ],
    );
  }
}

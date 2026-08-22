import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import 'stats_cubit.dart';
import 'widgets/activity_heatmap.dart';
import 'widgets/best_times_card.dart';
import 'widgets/difficulty_breakdown.dart';
import 'widgets/insight_card.dart';
import 'widgets/performance_sparkline.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final records = ctx.read<PuzzleRecordRepository>();
        final profiles = ctx.read<ProfileRepository>();
        return StatsCubit(
          records: records,
          profiles: profiles,
          intelligence: IntelligenceEngine(records, profiles),
        );
      },
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) {
            if (!state.loaded) return const SizedBox.shrink();

            if (state.allRecords.isEmpty) {
              return _buildEmptyState(context);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildHeader(context),
                  const SizedBox(height: 28),
                  _buildOverview(context, state),
                  const SizedBox(height: 28),
                  PerformanceSparkline(last14Days: state.last14Days),
                  const SizedBox(height: 28),
                  DifficultyBreakdown(byDifficulty: state.byDifficulty),
                  const SizedBox(height: 28),
                  ActivityHeatmap(allRecords: state.allRecords),
                  const SizedBox(height: 28),
                  if (state.profile != null)
                    BestTimesCard(
                      records: state.byDifficulty[state.profile!.preferredDifficulty] ?? [],
                      difficulty: state.profile!.preferredDifficulty,
                    ),
                  if (state.insight != null) ...[
                    const SizedBox(height: 28),
                    InsightCard(text: state.insight!),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final col = context.appColors;
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: col.paper,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.ink, width: 2),
              boxShadow: col.cardShadow,
            ),
            child: Center(
              child: Icon(Icons.arrow_back_ios_new, color: col.ink, size: 14),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text('stats', style: AppTypography.heading.copyWith(color: col.textPrimary)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final col = context.appColors;
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildHeader(context),
        const Spacer(),
        Center(
          child: Text(
            'play a puzzle.\nstats show up here.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: col.textSecondary),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildOverview(BuildContext context, StatsState state) {
    final col = context.appColors;
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: col.surface,
        borderRadius: BorderRadius.circular(col.isLight ? 8 : 8),
        border: Border.all(
          color: col.outline,
          width: col.isLight ? 2 : 0.5,
        ),
        boxShadow: col.isLight ? col.cardShadow : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _overviewStat(col, '${profile.currentStreak}', 'streak'),
          _overviewDivider(col),
          _overviewStat(col, '${profile.totalSolved}', 'solved'),
          _overviewDivider(col),
          _overviewStat(col, '${state.avgQuality}', 'avg quality'),
        ],
      ),
    );
  }

  Widget _overviewStat(AppThemeColors col, String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.number.copyWith(color: col.textPrimary, fontSize: 22),
        ),
        const SizedBox(height: 4),
        Text(label, style: AppTypography.labelSmall.copyWith(color: col.textSecondary)),
      ],
    );
  }

  Widget _overviewDivider(AppThemeColors col) {
    return Container(
      width: col.isLight ? 1.5 : 0.5,
      height: 32,
      color: col.outline.withValues(alpha: col.isLight ? 0.4 : 1),
    );
  }
}

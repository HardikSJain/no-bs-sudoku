import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
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
    final storage = StorageService.instance;
    return BlocProvider(
      create: (_) => StatsCubit(storage, IntelligenceEngine(storage)),
      child: const _StatsView(),
    );
  }
}

class _StatsView extends StatelessWidget {
  const _StatsView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: BlocBuilder<StatsCubit, StatsState>(
          builder: (context, state) {
            if (!state.loaded) {
              return const SizedBox.shrink();
            }

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
                  _buildOverview(state),
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
    return Row(
      children: [
        GestureDetector(
          onTap: () => context.pop(),
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          'stats',
          style: AppTypography.heading.copyWith(color: AppColors.textPrimary),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 16),
        _buildHeader(context),
        const Spacer(),
        Center(
          child: Text(
            'play a puzzle.\nstats show up here.',
            textAlign: TextAlign.center,
            style: AppTypography.body.copyWith(color: AppColors.textSecondary),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildOverview(StatsState state) {
    final profile = state.profile;
    if (profile == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _overviewStat('${profile.currentStreak}', 'streak'),
          _overviewDivider(),
          _overviewStat('${profile.totalSolved}', 'solved'),
          _overviewDivider(),
          _overviewStat('${state.avgQuality}', 'avg quality'),
        ],
      ),
    );
  }

  Widget _overviewStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.number.copyWith(
            color: AppColors.textPrimary,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }

  Widget _overviewDivider() {
    return Container(
      width: 0.5,
      height: 32,
      color: AppColors.border,
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'home_cubit.dart';
import 'widgets/daily_puzzle_card.dart';
import 'widgets/stats_strip.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = StorageService.instance;
    return BlocProvider(
      create: (_) => HomeCubit(storage, IntelligenceEngine(storage)),
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatelessWidget {
  const _HomeView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: BlocBuilder<HomeCubit, HomeState>(
            builder: (context, state) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  _buildHeader(context),
                  const SizedBox(height: 24),
                  DailyPuzzleCard(
                    completed: state.dailyCompleted,
                    timeSeconds: state.dailyTimeSeconds,
                    difficulty: state.dailyDifficulty,
                    puzzleNum: state.dailyPuzzleNum,
                    onTap: () => context.push('/game/hard'),
                  ),
                  const SizedBox(height: 28),
                  _buildDifficultySection(context, state),
                  const SizedBox(height: 24),
                  StatsStrip(
                    currentStreak: state.currentStreak,
                    totalSolved: state.totalSolved,
                    avgQuality: state.avgQuality,
                    onTap: () {}, // TODO: navigate to /stats when built
                  ),
                  if (state.insight != null) ...[
                    const SizedBox(height: 20),
                    Text(
                      state.insight!,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const Spacer(),
                  _buildFooter(),
                  const SizedBox(height: 20),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Text(
          'no bs sudoku',
          style: AppTypography.wordmark.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () {}, // TODO: navigate to /settings when built
          behavior: HitTestBehavior.opaque,
          child: const Padding(
            padding: EdgeInsets.all(4),
            child: Icon(
              Icons.settings_outlined,
              color: AppColors.textSecondary,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDifficultySection(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'new game',
          style: AppTypography.label.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        _DifficultyTile(
          label: 'easy',
          description: 'good for warming up',
          isRecommended: state.recommendedDifficulty == 'easy',
          onTap: () => _startGame(context, 'easy'),
        ),
        _DifficultyTile(
          label: 'medium',
          description: 'the sweet spot',
          isRecommended: state.recommendedDifficulty == 'medium',
          onTap: () => _startGame(context, 'medium'),
        ),
        _DifficultyTile(
          label: 'hard',
          description: 'bring some focus',
          isRecommended: state.recommendedDifficulty == 'hard',
          onTap: () => _startGame(context, 'hard'),
        ),
        _DifficultyTile(
          label: 'expert',
          description: 'no hand-holding',
          isRecommended: state.recommendedDifficulty == 'expert',
          onTap: () => _startGame(context, 'expert'),
        ),
      ],
    );
  }

  void _startGame(BuildContext context, String difficulty) {
    HapticFeedback.lightImpact();
    context.push('/game/$difficulty');
  }

  Widget _buildFooter() {
    return Text(
      'just sudoku.',
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.textDisabled,
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final String label;
  final String description;
  final bool isRecommended;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.label,
    required this.description,
    required this.isRecommended,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: const BorderSide(color: AppColors.border, width: 0.5),
            left: isRecommended
                ? const BorderSide(color: AppColors.accent, width: 2)
                : BorderSide.none,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.only(left: isRecommended ? 12 : 0),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: AppTypography.body.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: AppColors.textDisabled,
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

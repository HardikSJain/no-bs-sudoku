import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
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

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
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
                        onTap: () => context.push('/game/daily'),
                      ),
                      const SizedBox(height: 28),
                      _buildDifficultySection(context, state),
                      const SizedBox(height: 24),
                      StatsStrip(
                        currentStreak: state.currentStreak,
                        totalSolved: state.totalSolved,
                        avgQuality: state.avgQuality,
                        onTap: () => context.push('/stats'),
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
                  ),
                ),
                // Floating resume bar at bottom
                if (state.savedGame != null)
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 16,
                    child: _buildResumeBar(context, state),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildResumeBar(BuildContext context, HomeState state) {
    final saved = state.savedGame!;
    final m = saved.elapsedSeconds ~/ 60;
    final s = saved.elapsedSeconds % 60;
    final time = '$m:${s.toString().padLeft(2, '0')}';

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        context.push('/game/resume', extra: saved);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.accent.withValues(alpha: 0.3), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppColors.accent,
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'resume · ${saved.difficulty}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '$time elapsed',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                context.read<HomeCubit>().dismissSavedGame();
              },
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(
                  Icons.close_rounded,
                  color: AppColors.textDisabled,
                  size: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
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
          onTap: () => context.push('/settings'),
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
    // Starting a new game clears any saved game
    StorageService.instance.deleteSavedGame();
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

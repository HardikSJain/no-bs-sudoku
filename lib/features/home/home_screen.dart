import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/logger.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../engine/sudoku_solver.dart';
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
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    state.savedGame != null ? 80 : 0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.lg),
                      DailyPuzzleCard(
                        completed: state.dailyCompleted,
                        timeSeconds: state.dailyTimeSeconds,
                        difficulty: state.dailyDifficulty,
                        puzzleNum: state.dailyPuzzleNum,
                        onTap: () => _startDaily(context),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDifficultySection(context, state),
                      const SizedBox(height: AppSpacing.lg),
                      StatsStrip(
                        currentStreak: state.currentStreak,
                        totalSolved: state.totalSolved,
                        avgQuality: state.avgQuality,
                        onTap: () => context.push('/stats'),
                      ),
                      if (state.insight != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          state.insight!,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        ),
                      ],
                      _buildFooter(),
                    ],
                  ),
                ),
                if (state.savedGame != null)
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
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
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.accent.withValues(alpha: 0.4),
            width: 1,
          ),
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
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.accentSubtle,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.5),
                  width: 1,
                ),
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
              child: const SizedBox(
                width: 44,
                height: 44,
                child: Center(
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.textDisabled,
                    size: 16,
                  ),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.lg),
      child: Row(
        children: [
          Text(
            'no bs sudoku',
            style: AppTypography.wordmark.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/settings'),
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.settings_outlined,
                  color: AppColors.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(BuildContext context, HomeState state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < Difficulty.values.length; i++)
          _DifficultyTile(
            label: Difficulty.values[i].name,
            description: Difficulty.values[i].description,
            isRecommended: state.recommendedDifficulty == Difficulty.values[i],
            isLast: i == Difficulty.values.length - 1,
            onTap: () => _startGame(context, Difficulty.values[i]),
          )
              .animate(delay: (i * 40).ms)
              .fadeIn(duration: 200.ms)
              .slideY(
                begin: 0.04,
                end: 0,
                duration: 200.ms,
                curve: Curves.easeOut,
              ),
      ],
    );
  }

  Future<void> _startGame(BuildContext context, Difficulty difficulty) async {
    HapticFeedback.lightImpact();
    Log.difficultySelected(difficulty: difficulty.name);
    await StorageService.instance.deleteSavedGame();
    if (!context.mounted) return;
    context.push('/game/${difficulty.name}');
  }

  Future<void> _startDaily(BuildContext context) async {
    HapticFeedback.lightImpact();
    final state = context.read<HomeCubit>().state;
    Log.dailyPuzzleTapped(alreadyCompleted: state.dailyCompleted);
    await StorageService.instance.deleteSavedGame();
    if (!context.mounted) return;
    context.push('/game/daily');
  }

  Widget _buildFooter() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          'just sudoku.',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textDisabled,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DifficultyTile extends StatelessWidget {
  final String label;
  final String description;
  final bool isRecommended;
  final bool isLast;
  final VoidCallback onTap;

  const _DifficultyTile({
    required this.label,
    required this.description,
    required this.isRecommended,
    required this.isLast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      splashColor: AppColors.accentSubtle,
      highlightColor: Colors.transparent,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 3,
              decoration: BoxDecoration(
                color: isRecommended ? AppColors.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.md,
                      horizontal: 12,
                    ),
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
                  if (!isLast)
                    Divider(
                      height: 0.5,
                      thickness: 0.5,
                      color: AppColors.border,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

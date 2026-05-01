import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/logger.dart';
import '../../core/storage/storage_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
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
                        inProgressGame: (state.savedGame?.isDaily == true && !state.dailyCompleted)
                            ? state.savedGame
                            : null,
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
                        Builder(builder: (ctx) => Text(
                          state.insight!,
                          style: AppTypography.labelSmall.copyWith(
                            color: ctx.appColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        )),
                      ],
                      _buildFooter(context),
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
    final col = context.appColors;
    final m = saved.elapsedSeconds ~/ 60;
    final s = saved.elapsedSeconds % 60;
    final time = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: col.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: col.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IN PROGRESS',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${saved.difficulty}  ·  $time',
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/game/resume', extra: saved);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: col.sun,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CONTINUE →',
                style: AppTypography.labelSmall.copyWith(
                  color: col.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildHeader(BuildContext context) {
    final col = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.lg),
      child: Row(
        children: [
          Text(
            'no bs sudoku',
            style: AppTypography.wordmark.copyWith(
              color: col.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.push('/settings'),
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.settings_outlined,
                  color: col.textSecondary,
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
    final difficulties = Difficulty.values;
    final col = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEW GAME',
          style: AppTypography.labelSmall.copyWith(
            color: col.ink3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DifficultyCard(
                index: 0,
                difficulty: difficulties[0],
                isRecommended: state.recommendedDifficulty == difficulties[0],
                bestTimeSecs: state.bestTimes[difficulties[0].name],
                onTap: () => _startGame(context, difficulties[0]),
              ).animate(delay: 0.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DifficultyCard(
                index: 1,
                difficulty: difficulties[1],
                isRecommended: state.recommendedDifficulty == difficulties[1],
                bestTimeSecs: state.bestTimes[difficulties[1].name],
                onTap: () => _startGame(context, difficulties[1]),
              ).animate(delay: 40.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DifficultyCard(
                index: 2,
                difficulty: difficulties[2],
                isRecommended: state.recommendedDifficulty == difficulties[2],
                bestTimeSecs: state.bestTimes[difficulties[2].name],
                onTap: () => _startGame(context, difficulties[2]),
              ).animate(delay: 80.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DifficultyCard(
                index: 3,
                difficulty: difficulties[3],
                isRecommended: state.recommendedDifficulty == difficulties[3],
                bestTimeSecs: state.bestTimes[difficulties[3].name],
                onTap: () => _startGame(context, difficulties[3]),
              ).animate(delay: 120.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
          ],
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

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          'just sudoku.',
          style: AppTypography.labelSmall.copyWith(
            color: context.appColors.textDisabled,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final int index;
  final Difficulty difficulty;
  final bool isRecommended;
  final int? bestTimeSecs;
  final VoidCallback onTap;

  static const _clueRanges = {
    'easy': '36–38 clues',
    'medium': '30–33 clues',
    'hard': '26–29 clues',
    'expert': '22–28 clues',
  };

  const _DifficultyCard({
    required this.index,
    required this.difficulty,
    required this.isRecommended,
    required this.onTap,
    this.bestTimeSecs,
  });

  String? _formatTime(int? secs) {
    if (secs == null || secs == 0) return null;
    final m = secs ~/ 60;
    final s = secs % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final diffColor = col.difficultyColor(difficulty.name);
    final num = (index + 1).toString().padLeft(2, '0');
    final bestTime = _formatTime(bestTimeSecs);
    final clues = _clueRanges[difficulty.name] ?? '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: diffColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Faded large number watermark
            Positioned(
              bottom: -10,
              right: 4,
              child: Text(
                num,
                style: AppTypography.number.copyWith(
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  color: col.ink.withValues(alpha: 0.08),
                  height: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Faded number label top-left
                  Text(
                    num,
                    style: AppTypography.number.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: col.ink.withValues(alpha: 0.35),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    difficulty.name,
                    style: AppTypography.body.copyWith(
                      color: col.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Text(
                        clues,
                        style: AppTypography.labelSmall.copyWith(
                          color: col.ink.withValues(alpha: 0.55),
                          fontSize: 9,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        bestTime ?? '—',
                        style: AppTypography.number.copyWith(
                          color: col.ink.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // "★ FOR YOU" sticker
            if (isRecommended)
              Positioned(
                top: -4,
                right: 10,
                child: Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: col.accent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: col.ink, width: 1.5),
                      boxShadow: [BoxShadow(color: col.ink, offset: const Offset(1, 1), blurRadius: 0)],
                    ),
                    child: Text(
                      '★ FOR YOU',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

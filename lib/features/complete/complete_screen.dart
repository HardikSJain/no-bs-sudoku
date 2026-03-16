import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/intelligence/velocity_profile.dart';
import '../../core/logger.dart';
import '../../core/routing/route_args.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import 'complete_cubit.dart';
import 'widgets/checkmark_painter.dart';
import 'widgets/quality_bar.dart';
import 'widgets/solve_replay.dart';
import 'widgets/stats_grid.dart';

class CompleteScreen extends StatefulWidget {
  final CompleteRouteArgs args;

  const CompleteScreen({
    super.key,
    required this.args,
  });

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen>
    with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _qualityController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _qualityController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Start checkmark at 100ms
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) _checkController.forward();
    });
    // Start quality bar at 1450ms
    Future.delayed(const Duration(milliseconds: 1450), () {
      if (mounted) _qualityController.forward();
    });

    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m min $s sec';
  }

  String _formatTimeShort(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(1, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return BlocProvider(
      create: (_) => CompleteCubit(
        qualityScore: a.qualityScore,
        timeSeconds: a.timeSeconds,
        hintsUsed: a.hintsUsed,
        mistakes: a.mistakes,
        difficulty: a.difficulty,
        isDaily: a.isDaily,
        solveTimes: a.solveTimes,
      ),
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: BlocBuilder<CompleteCubit, CompleteState>(
              builder: (context, state) {
                return Column(
                  children: [
                    const Spacer(flex: 2),
                    _buildCheckmark(),
                    const SizedBox(height: 24),
                    _buildSolvedLabel(),
                    const SizedBox(height: 8),
                    _buildDifficultyTime(),
                    const SizedBox(height: 28),
                    _buildStatsGrid(state),
                    const SizedBox(height: 20),
                    _buildStreakAndVelocity(state),
                    if (widget.args.puzzleDna != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.args.puzzleDna!,
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textDisabled,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 1350.ms, duration: 200.ms),
                    ],
                    const SizedBox(height: 28),
                    _buildQualityBar(),
                    if (widget.args.puzzle != null && widget.args.history.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SolveReplay(
                        puzzle: widget.args.puzzle!,
                        history: widget.args.history,
                      )
                          .animate()
                          .fadeIn(delay: 1800.ms, duration: 200.ms),
                    ],
                    const Spacer(flex: 2),
                    _buildActions(state),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    return SizedBox(
      width: 48,
      height: 48,
      child: AnimatedBuilder(
        animation: _checkController,
        builder: (_, _) => CustomPaint(
          painter: CheckmarkPainter(
            progress: Curves.easeOutCubic.transform(_checkController.value),
          ),
        ),
      ),
    );
  }

  Widget _buildSolvedLabel() {
    return Text(
      'Solved.',
      style: AppTypography.heading.copyWith(
        color: AppColors.textPrimary,
        fontSize: 24,
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 200.ms);
  }

  Widget _buildDifficultyTime() {
    return Text(
      '${widget.args.difficulty.name} · ${_formatTime(widget.args.timeSeconds)}',
      style: AppTypography.label.copyWith(
        color: AppColors.textSecondary,
      ),
    )
        .animate()
        .fadeIn(delay: 900.ms, duration: 150.ms);
  }

  Widget _buildStatsGrid(CompleteState state) {
    return StatsGrid(
      time: _formatTimeShort(widget.args.timeSeconds),
      hints: widget.args.hintsUsed,
      mistakes: widget.args.mistakes,
      comparison: state.comparison,
    )
        .animate()
        .fadeIn(delay: 1050.ms, duration: 200.ms);
  }

  Widget _buildStreakAndVelocity(CompleteState state) {
    return Column(
      children: [
        if (state.currentStreak > 0)
          Text(
            '🔥 ${state.currentStreak} day streak',
            style: AppTypography.label.copyWith(
              color: AppColors.textPrimary,
            ),
          ),
        if (state.velocity != null) ...[
          const SizedBox(height: 4),
          Text(
            state.velocity!.copy,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ],
    )
        .animate()
        .fadeIn(delay: 1250.ms, duration: 200.ms)
        .slideY(begin: 0.15, end: 0, delay: 1250.ms, duration: 200.ms, curve: Curves.easeOut);
  }

  Widget _buildQualityBar() {
    return QualityBar(
      score: widget.args.qualityScore,
      fillAnimation: CurvedAnimation(
        parent: _qualityController,
        curve: Curves.easeOut,
      ),
    );
  }

  Widget _buildActions(CompleteState state) {
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => _share(state),
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border, width: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'share result',
                  style: AppTypography.button.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.go('/home');
            },
            behavior: HitTestBehavior.opaque,
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.accent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'new puzzle',
                  style: AppTypography.button.copyWith(
                    color: AppColors.background,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 2000.ms, duration: 200.ms);
  }

  void _share(CompleteState state) {
    HapticFeedback.lightImpact();
    final a = widget.args;
    Log.shareResult(
      difficulty: a.difficulty.name,
      isDaily: a.isDaily,
      qualityScore: a.qualityScore.round(),
    );
    final time = _formatTimeShort(a.timeSeconds);
    final quality = a.qualityScore.round();

    String text;
    if (a.isDaily) {
      text = 'no bs sudoku 🧩\n'
          'Daily — ${a.difficulty.name}\n'
          '✅ $time · ${a.hintsUsed} hints · ${a.mistakes} mistakes\n'
          '⚡ $quality/100 quality\n'
          '${state.currentStreak > 0 ? '🔥 ${state.currentStreak} streak\n' : ''}'
          'nobssudoku.app';
    } else {
      text = 'no bs sudoku 🧩\n'
          '${a.difficulty.name} puzzle\n'
          '✅ $time · ${a.hintsUsed} hints · ${a.mistakes} mistakes\n'
          '⚡ $quality/100\n'
          'nobssudoku.app';
    }

    SharePlus.instance.share(ShareParams(text: text));
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/intelligence/velocity_profile.dart';
import '../../core/logger.dart';
import '../../core/routing/route_args.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/a11y/tappable.dart';
import '../../core/share_origin.dart';
import '../../engine/deduction/puzzle_dna.dart';
import '../game/technique_copy.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import 'complete_cubit.dart';
import 'widgets/checkmark_painter.dart';
import 'widgets/quality_bar.dart';
import 'widgets/solve_path_card.dart';
import 'widgets/solve_replay.dart';
import 'widgets/stats_grid.dart';

class CompleteScreen extends StatefulWidget {
  final CompleteRouteArgs args;

  const CompleteScreen({super.key, required this.args});

  @override
  State<CompleteScreen> createState() => _CompleteScreenState();
}

class _CompleteScreenState extends State<CompleteScreen> with TickerProviderStateMixin {
  late final AnimationController _checkController;
  late final AnimationController _qualityController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _qualityController = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));

    Future.delayed(const Duration(milliseconds: 100), () { if (mounted) _checkController.forward(); });
    Future.delayed(const Duration(milliseconds: 1400), () { if (mounted) _qualityController.forward(); });

    HapticFeedback.mediumImpact();
  }

  @override
  void dispose() {
    _checkController.dispose();
    _qualityController.dispose();
    super.dispose();
  }

  String _formatTimeShort(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.args;
    return BlocProvider(
      create: (ctx) => CompleteCubit(
        records: ctx.read<PuzzleRecordRepository>(),
        profiles: ctx.read<ProfileRepository>(),
        preferences: ctx.read<PreferencesRepository>(),
        puzzle: a.puzzle,
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
          child: BlocBuilder<CompleteCubit, CompleteState>(
            builder: (context, state) {
              return Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          _buildCheckmark(),
                          const SizedBox(height: 20),
                          _buildSolvedLabel(),
                          const SizedBox(height: 6),
                          _buildDifficultyLine(state),
                          const SizedBox(height: 24),
                          _buildStatsGrid(state),
                          if (state.currentStreak > 0) ...[
                            const SizedBox(height: 14),
                            _buildStreakCard(state),
                          ],
                          const SizedBox(height: 14),
                          _buildQualityBar(),
                          if (a.puzzle != null && a.history.isNotEmpty) ...[
                            const SizedBox(height: 14),
                            _buildReplayCard(),
                          ],
                          if (state.solvePath case final analysis?) ...[
                            const SizedBox(height: 14),
                            SolvePathCard(analysis: analysis)
                                .animate()
                                .fadeIn(delay: 1700.ms, duration: 200.ms),
                          ],
                          if (a.puzzleDna != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              a.puzzleDna!,
                              style: AppTypography.labelSmall.copyWith(
                                color: context.appColors.ink4,
                                fontStyle: FontStyle.italic,
                                fontSize: 11,
                              ),
                            ).animate().fadeIn(delay: 1800.ms, duration: 200.ms),
                          ],
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  _buildActions(context, state),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCheckmark() {
    final col = context.appColors;
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: col.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: col.ink, width: 2.5),
        boxShadow: [BoxShadow(color: col.ink, offset: const Offset(3, 3), blurRadius: 0)],
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _checkController,
          builder: (_, _) => CustomPaint(
            size: const Size(28, 28),
            painter: CheckmarkPainter(
              progress: Curves.easeOutCubic.transform(_checkController.value),
              color: col.ink,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSolvedLabel() {
    final col = context.appColors;
    return Text(
      'solved.',
      style: AppTypography.number.copyWith(
        color: col.ink,
        fontSize: 48,
        fontWeight: FontWeight.w700,
        letterSpacing: -1.5,
        height: 1,
      ),
    )
        .animate()
        .fadeIn(delay: 700.ms, duration: 200.ms)
        .slideY(begin: 0.08, end: 0, delay: 700.ms, duration: 250.ms, curve: Curves.easeOut);
  }

  Widget _buildDifficultyLine(CompleteState state) {
    final col = context.appColors;
    final a = widget.args;
    return Row(
      children: [
        Text(
          '${a.difficulty.name} · ${_formatTimeShort(a.timeSeconds)}',
          style: AppTypography.label.copyWith(color: col.ink3),
        ),
        if (state.isPersonalBest) ...[
          const SizedBox(width: 8),
          Transform.rotate(
            angle: -0.06,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: col.error,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: col.ink, width: 1.5),
                boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
              ),
              child: Text(
                '★ NEW PB',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 900.ms, duration: 150.ms);
  }

  Widget _buildStatsGrid(CompleteState state) {
    return StatsGrid(
      time: _formatTimeShort(widget.args.timeSeconds),
      hints: widget.args.hintsUsed,
      mistakes: widget.args.mistakes,
      pbDiffSeconds: state.pbDiffSeconds,
      avgDiffSeconds: state.avgDiffSeconds,
    ).animate().fadeIn(delay: 1050.ms, duration: 200.ms);
  }

  Widget _buildStreakCard(CompleteState state) {
    final col = context.appColors;
    final velocityLabel = _velocityLabel(state.velocity);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: col.accent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Text('🔥', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text(
                    '${state.currentStreak} day streak',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                '+1 today',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.white.withValues(alpha: 0.65),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          if (velocityLabel != null)
            Transform.rotate(
              angle: -0.08,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: col.sun,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: col.ink, width: 1.5),
                  boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
                ),
                child: Text(
                  velocityLabel,
                  style: AppTypography.labelSmall.copyWith(
                    color: col.ink,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 1200.ms, duration: 200.ms)
        .slideY(begin: 0.1, end: 0, delay: 1200.ms, duration: 200.ms, curve: Curves.easeOut);
  }

  String? _velocityLabel(VelocityProfile? v) => switch (v) {
        VelocityProfile.fastStart => 'STRONG START',
        VelocityProfile.slowStart => 'WARMED UP',
        VelocityProfile.steady => 'CONSISTENT',
        VelocityProfile.erratic => 'BURSTING',
        null => null,
      };

  Widget _buildQualityBar() {
    return QualityBar(
      score: widget.args.qualityScore,
      fillAnimation: CurvedAnimation(parent: _qualityController, curve: Curves.easeOut),
    ).animate().fadeIn(delay: 1350.ms, duration: 200.ms);
  }

  Widget _buildReplayCard() {
    final col = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'REPLAY YOUR SOLVE',
            style: AppTypography.labelSmall.copyWith(
              color: col.ink3,
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SolveReplay(
            puzzle: widget.args.puzzle!,
            history: widget.args.history,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1600.ms, duration: 200.ms);
  }

  Widget _buildActions(BuildContext context, CompleteState state) {
    final col = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Tappable(
              label: 'share your result',
              onTap: () => _share(state),
              behavior: HitTestBehavior.opaque,
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: col.paper,
                  border: Border.all(color: col.ink, width: 2),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: col.cardShadow,
                ),
                child: Center(
                  child: Text(
                    'share',
                    style: AppTypography.button.copyWith(color: col.ink3),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            flex: 3,
            child: Tappable(
              label: 'done',
              hint: 'back to home',
              onTap: () {
                HapticFeedback.lightImpact();
                context.go('/home');
              },
              child: Container(
                height: 50,
                decoration: BoxDecoration(
                  color: col.accent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: col.ink, width: 2),
                  boxShadow: col.cardShadow,
                ),
                child: Center(
                  child: Text(
                    'home →',
                    style: AppTypography.button.copyWith(color: Colors.white),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1800.ms, duration: 200.ms);
  }

  /// The hardest two techniques the puzzle needed. More than that stops
  /// being a spectrum and starts being a table nobody reads in a message.
  String _spectrumLine(PuzzleDna dna) {
    final top = dna.spectrum.take(2).map((e) => e.key.plural).join(' + ');
    return top.isEmpty ? '${dna.totalSteps} steps' : top;
  }

  void _share(CompleteState state) {
    HapticFeedback.lightImpact();
    final a = widget.args;
    Log.shareResult(difficulty: a.difficulty.name, isDaily: a.isDaily, qualityScore: a.qualityScore.round());
    final time = _formatTimeShort(a.timeSeconds);
    final quality = a.qualityScore.round();

    // The spectrum only goes out when the player has asked to see it. It is
    // the same opt-in as the analysis card — someone who does not want a
    // technique debrief certainly does not want to broadcast one.
    final dna = state.solvePath == null
        ? ''
        : '🧠 ${_spectrumLine(PuzzleDna.of(state.solvePath!))}\n';

    final text = a.isDaily
        ? 'no bs sudoku 🧩\nDaily — ${a.difficulty.name}\n✅ $time · ${a.hintsUsed} hints · ${a.mistakes} mistakes\n⚡ $quality/100 quality\n$dna${state.currentStreak > 0 ? '🔥 ${state.currentStreak} streak\n' : ''}nobssudoku.app'
        : 'no bs sudoku 🧩\n${a.difficulty.name} puzzle\n✅ $time · ${a.hintsUsed} hints · ${a.mistakes} mistakes\n⚡ $quality/100\n${dna}nobssudoku.app';

    SharePlus.instance.share(
      ShareParams(text: text, sharePositionOrigin: context.shareOrigin),
    );
  }
}

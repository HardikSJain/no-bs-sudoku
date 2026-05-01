import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/widgets/grid_loader.dart';
import '../../core/logger.dart';
import '../../core/routing/route_args.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/storage/app_database.dart';
import '../../engine/sudoku_solver.dart';
import 'game_cubit.dart';
import 'game_state.dart';
import 'widgets/sudoku_grid.dart';
import 'widgets/game_toolbar.dart';
import 'widgets/number_pad.dart';

class GameScreen extends StatelessWidget {
  final Difficulty difficulty;
  final bool isDaily;
  final SavedGame? resumeFrom;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.isDaily = false,
    this.resumeFrom,
  });

  @override
  Widget build(BuildContext context) {
    if (resumeFrom != null) {
      return BlocProvider(
        create: (_) => GameCubit.fromSaved(resumeFrom!)..startTimer(),
        child: const _GameView(),
      );
    }
    return _AsyncGameLoader(difficulty: difficulty, isDaily: isDaily);
  }
}

class _GameView extends StatefulWidget {
  const _GameView();

  @override
  State<_GameView> createState() => _GameViewState();
}

class _GameViewState extends State<_GameView> {
  late final AppLifecycleListener _lifecycleListener;

  @override
  void initState() {
    super.initState();
    _lifecycleListener = AppLifecycleListener(
      onInactive: () {
        context.read<GameCubit>().pauseTimer();
        context.read<GameCubit>().saveCurrentGame();
      },
      onResume: () => context.read<GameCubit>().resumeTimer(),
    );
  }

  @override
  void dispose() {
    _lifecycleListener.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        if (state.status == GameStatus.complete) {
          Haptics.complete();
          final cubit = context.read<GameCubit>();
          // Wait for record + streak writes before navigating
          await cubit.saveComplete;
          if (!context.mounted) return;
          context.go(
            '/complete',
            extra: CompleteRouteArgs(
              qualityScore: cubit.qualityScore,
              timeSeconds: state.elapsed.inSeconds,
              hintsUsed: cubit.hintsUsed,
              mistakes: state.mistakeCount,
              difficulty: state.difficulty,
              isDaily: state.isDaily,
              solveTimes: cubit.solveTimes,
              techniques: cubit.techniques,
              puzzle: state.puzzle,
              history: state.history,
            ),
          );
        } else if (state.status == GameStatus.abandoned) {
          if (!context.mounted) return;
          context.go('/home');
        }
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final cubit = context.read<GameCubit>();
          Log.puzzlePaused(
            difficulty: cubit.state.difficulty.name,
            elapsedSeconds: cubit.state.elapsed.inSeconds,
          );
          await cubit.saveCurrentGame();
          if (context.mounted) context.go('/home');
        },
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                _GameHeader(),
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                      ),
                      child: const SudokuGrid(),
                    ),
                  ),
                ),
                const GameToolbar(),
                const SizedBox(height: AppSpacing.md),
                const NumberPad(),
                const SizedBox(height: AppSpacing.lg),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GameHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return BlocBuilder<GameCubit, GameState>(
      buildWhen: (prev, curr) =>
          prev.elapsed != curr.elapsed ||
          prev.showTimer != curr.showTimer ||
          prev.isOnPbPace != curr.isOnPbPace ||
          prev.mistakeCount != curr.mistakeCount ||
          prev.mistakeLimit != curr.mistakeLimit,
      builder: (context, state) {
        final mins = state.elapsed.inMinutes.toString().padLeft(2, '0');
        final secs = (state.elapsed.inSeconds % 60).toString().padLeft(2, '0');
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              // back button — paper card
              GestureDetector(
                onTap: () async {
                  await context.read<GameCubit>().saveCurrentGame();
                  if (context.mounted) context.go('/home');
                },
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
                    child: Icon(
                      Icons.arrow_back_ios_new,
                      color: col.ink,
                      size: 14,
                    ),
                  ),
                ),
              ),
              // center — difficulty sticker + timer
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DifficultySticker(
                      difficulty: state.difficulty.name,
                      col: col,
                    ),
                    if (state.showTimer) ...[
                      const SizedBox(height: 4),
                      Text(
                        '$mins:$secs',
                        style: AppTypography.number.copyWith(
                          fontSize: 22,
                          fontWeight: FontWeight.w500,
                          color: col.ink,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                    if (state.isOnPbPace)
                      _StickerLabel(
                            text: '★ pb pace',
                            color: col.mint,
                            angle: -0.03,
                          )
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .then()
                          .fadeOut(delay: 3.seconds, duration: 500.ms),
                  ],
                ),
              ),
              // right — mistake counter
              _MistakePips(
                count: state.mistakeCount,
                limit: state.mistakeLimit,
                col: col,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DifficultySticker extends StatelessWidget {
  final String difficulty;
  final AppThemeColors col;
  const _DifficultySticker({required this.difficulty, required this.col});

  Color get _color => AppThemeColors.difficultyColors[difficulty] ?? col.sun;

  @override
  Widget build(BuildContext context) {
    return Transform.rotate(
      angle: -0.04,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: _color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: col.ink, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: col.ink,
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          difficulty,
          style: AppTypography.labelSmall.copyWith(
            color: col.ink,
            fontWeight: FontWeight.w700,
            fontSize: 10,
            letterSpacing: 0.4,
          ),
        ),
      ),
    );
  }
}

class _StickerLabel extends StatelessWidget {
  final String text;
  final Color color;
  final double angle;
  const _StickerLabel({
    required this.text,
    required this.color,
    required this.angle,
  });

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Transform.rotate(
      angle: angle,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: col.ink, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: col.ink,
              offset: const Offset(2, 2),
              blurRadius: 0,
            ),
          ],
        ),
        child: Text(
          text,
          style: AppTypography.labelSmall.copyWith(
            color: col.ink,
            fontWeight: FontWeight.w700,
            fontSize: 9,
            letterSpacing: 0.6,
          ),
        ),
      ),
    );
  }
}

class _MistakePips extends StatelessWidget {
  final int count;
  final int limit;
  final AppThemeColors col;
  const _MistakePips({
    required this.count,
    required this.limit,
    required this.col,
  });

  @override
  Widget build(BuildContext context) {
    if (limit == 0) return const SizedBox(width: 36);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(limit, (i) {
          final filled = i < count;
          return Container(
            width: 7,
            height: 7,
            margin: EdgeInsets.only(left: i > 0 ? 3 : 0),
            decoration: BoxDecoration(
              color: filled ? col.error : col.background2,
              shape: BoxShape.circle,
              border: Border.all(color: col.ink, width: 1),
            ),
          );
        }),
      ),
    );
  }
}

/// Loads the GameCubit asynchronously (puzzle generated on isolate).
class _AsyncGameLoader extends StatefulWidget {
  final Difficulty difficulty;
  final bool isDaily;

  const _AsyncGameLoader({required this.difficulty, required this.isDaily});

  @override
  State<_AsyncGameLoader> createState() => _AsyncGameLoaderState();
}

class _AsyncGameLoaderState extends State<_AsyncGameLoader> {
  GameCubit? _cubit;
  bool _minDelayDone = false;

  @override
  void initState() {
    super.initState();
    _generate();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() => _minDelayDone = true);
    });
  }

  Future<void> _generate() async {
    final cubit = widget.isDaily
        ? await GameCubit.dailyAsync(date: DateTime.now())
        : await GameCubit.newGameAsync(difficulty: widget.difficulty);
    if (!mounted) {
      cubit.close();
      return;
    }
    setState(() => _cubit = cubit..startTimer());
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null || !_minDelayDone) {
      return const Scaffold(body: Center(child: GridLoader()));
    }
    return BlocProvider.value(value: cubit, child: const _GameView());
  }
}

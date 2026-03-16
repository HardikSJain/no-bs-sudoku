import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/haptics.dart';
import '../../core/logger.dart';
import '../../core/routing/route_args.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
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
          context.go('/complete', extra: CompleteRouteArgs(
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
          ));
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.md,
        0,
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await context.read<GameCubit>().saveCurrentGame();
              if (context.mounted) context.go('/home');
            },
            behavior: HitTestBehavior.opaque,
            child: const SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.arrow_back_ios_new,
                  color: AppColors.textSecondary,
                  size: 18,
                ),
              ),
            ),
          ),
          Expanded(
            child: Center(
              child: BlocBuilder<GameCubit, GameState>(
                buildWhen: (prev, curr) =>
                    prev.elapsed != curr.elapsed ||
                    prev.showTimer != curr.showTimer,
                builder: (context, state) {
                  final cubit = context.read<GameCubit>();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (state.showTimer)
                        Text(
                          '${state.elapsed.inMinutes.toString().padLeft(2, '0')}:${(state.elapsed.inSeconds % 60).toString().padLeft(2, '0')}',
                          style: AppTypography.label.copyWith(
                            color: AppColors.textDisabled,
                          ),
                        ),
                      if (cubit.isOnPbPace)
                        Text(
                          'on pb pace',
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.accent,
                            fontSize: 10,
                          ),
                        )
                            .animate()
                            .fadeIn(duration: 300.ms)
                            .then()
                            .fadeOut(delay: 3.seconds, duration: 500.ms),
                    ],
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
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

  @override
  void initState() {
    super.initState();
    _generate();
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
    // Only close if we created it but never mounted it in BlocProvider
    if (_cubit == null) return;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (cubit == null) {
      return const Scaffold(
        body: Center(
          child: SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.accent,
            ),
          ),
        ),
      );
    }
    return BlocProvider.value(
      value: cubit,
      child: const _GameView(),
    );
  }
}

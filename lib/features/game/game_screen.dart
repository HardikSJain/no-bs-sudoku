import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

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
    return BlocProvider(
      create: (_) {
        if (resumeFrom != null) {
          return GameCubit.fromSaved(resumeFrom!)..startTimer();
        }
        if (isDaily) {
          return GameCubit.daily(date: DateTime.now())..startTimer();
        }
        return GameCubit.newGame(difficulty: difficulty)..startTimer();
      },
      child: const _GameView(),
    );
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
      onInactive: () => context.read<GameCubit>().saveCurrentGame(),
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
          HapticFeedback.mediumImpact();
          final cubit = context.read<GameCubit>();
          // Wait for record + streak writes before navigating
          await cubit.saveComplete;
          if (!context.mounted) return;
          context.go('/complete', extra: {
            'qualityScore': cubit.qualityScore,
            'timeSeconds': state.elapsed.inSeconds,
            'hintsUsed': cubit.hintsUsed,
            'mistakes': state.mistakeCount,
            'difficulty': state.difficulty,
            'isDaily': state.isDaily,
            'solveTimes': cubit.solveTimes,
          });
        }
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
                  if (!state.showTimer) return const SizedBox.shrink();
                  final mins = state.elapsed.inMinutes;
                  final secs = state.elapsed.inSeconds % 60;
                  return Text(
                    '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}',
                    style: AppTypography.label.copyWith(
                      color: AppColors.textDisabled,
                    ),
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

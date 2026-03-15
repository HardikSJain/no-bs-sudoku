import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../engine/sudoku_solver.dart';
import 'game_cubit.dart';
import 'game_state.dart';
import 'widgets/sudoku_grid.dart';
import 'widgets/game_toolbar.dart';
import 'widgets/number_pad.dart';

class GameScreen extends StatelessWidget {
  final Difficulty difficulty;

  const GameScreen({super.key, required this.difficulty});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GameCubit.newGame(difficulty: difficulty)..startTimer(),
      child: const _GameView(),
    );
  }
}

class _GameView extends StatelessWidget {
  const _GameView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<GameCubit, GameState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) {
        if (state.status == GameStatus.complete) {
          HapticFeedback.mediumImpact();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: SafeArea(
          child: Column(
            children: [
              _buildTopBar(context),
              const Spacer(),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: const SudokuGrid(),
              ),
              const SizedBox(height: 32),
              const GameToolbar(),
              const SizedBox(height: 24),
              const NumberPad(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
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
          const Spacer(),
          BlocBuilder<GameCubit, GameState>(
            buildWhen: (prev, curr) => prev.elapsed != curr.elapsed,
            builder: (context, state) {
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
          const Spacer(),
          const SizedBox(width: 28),
        ],
      ),
    );
  }
}

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/daily_key.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/a11y/tappable.dart';
import '../../core/duration_format.dart';
import '../../core/haptics.dart';
import '../../core/widgets/grid_loader.dart';
import '../../core/logger.dart';
import '../../core/routing/route_args.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/storage/app_database.dart';
import '../../engine/deduction/deduction.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';
import 'game_cubit.dart';
import 'game_state.dart';
import 'widgets/sudoku_grid.dart';
import 'widgets/game_toolbar.dart';
import 'widgets/hint_panel.dart';
import 'widgets/number_pad.dart';
import 'technique_copy.dart';

class GameScreen extends StatelessWidget {
  final Difficulty difficulty;
  final bool isDaily;

  /// Which daily. Null means today's, which is what the home card asks for;
  /// the archive names a past date.
  final DateTime? dailyDate;
  final SavedGame? resumeFrom;

  /// Set for a one-move technique drill rather than a full puzzle.
  final Technique? drillTechnique;

  /// Set for a grid the player typed or pasted in, with the answer already
  /// verified by the import screen.
  final SudokuBoard? importedPuzzle;
  final SudokuBoard? importedSolution;

  const GameScreen({
    super.key,
    required this.difficulty,
    this.isDaily = false,
    this.dailyDate,
    this.resumeFrom,
    this.drillTechnique,
    this.importedPuzzle,
    this.importedSolution,
  });

  @override
  Widget build(BuildContext context) {
    if (resumeFrom != null) {
      return BlocProvider(
        create: (_) => GameCubit.fromSaved(resumeFrom!, context.read<Repositories>())..startTimer(),
        child: const _GameView(),
      );
    }
    // Nothing to generate: the board is already in hand.
    if (importedPuzzle case final puzzle?) {
      return BlocProvider(
        create: (ctx) => GameCubit.imported(
          repos: ctx.read<Repositories>(),
          puzzle: puzzle,
          solution: importedSolution!,
        )..startTimer(),
        child: const _GameView(),
      );
    }

    return _AsyncGameLoader(
      difficulty: difficulty,
      isDaily: isDaily,
      dailyDate: dailyDate,
      drillTechnique: drillTechnique,
      repos: context.read<Repositories>(),
    );
  }
}

/// Everything below the board that the board must not fight with: the header,
/// the fixed gap under it, the toolbar, the number pad, their spacing, and the
/// tallest the hint panel gets.
///
/// The panel's share is reserved whether or not a hint is showing. Giving it
/// back when there is no hint would make the board grow and shrink as hints
/// come and go, which is the exact thing this avoids.
///
/// Measured off a rendered screen rather than estimated: erring high wastes
/// board, erring low overflows the column.
@visibleForTesting
const double gameFixedChromeHeight = 48 + 20 + 92 + 55 + 40;

@visibleForTesting
const double gameChromeHeight = gameFixedChromeHeight + hintPanelMinHeight;

/// How tall the hint panel is allowed to get on this particular screen.
///
/// The board reserves [hintPanelMinHeight] and no more, so on anything taller
/// than that reservation needs there is slack left over — on a 6.3" phone the
/// board is limited by the width, and the slack is the better part of a
/// hundred and fifty points sitting empty. Handing it to the panel means a
/// long explanation is read rather than scrolled, and costs nothing: the
/// board is already sized, and the flexible gap above the panel gives the
/// space back when there is no hint.
@visibleForTesting
double hintPanelHeightFor(BoxConstraints constraints) {
  final slack =
      constraints.maxHeight - gameFixedChromeHeight - gameBoardSize(constraints);
  return slack.clamp(0.0, hintPanelCeiling);
}

/// The board's edge length for a given screen.
///
/// Public so the invariant can be tested directly: this must not take the
/// hint panel's visibility as an input. The panel's height is already
/// reserved in [gameChromeHeight], so the answer is the same whether or not a
/// hint is on screen — which is the whole point.
@visibleForTesting
double gameBoardSize(BoxConstraints constraints) {
  final byWidth = constraints.maxWidth - AppSpacing.md * 2;
  final byHeight = constraints.maxHeight - gameChromeHeight;
  // A short screen gives up some board rather than clipping the pad, but not
  // below a size where a cell stops being a comfortable target.
  var size = byWidth < byHeight ? byWidth : byHeight.clamp(boardFloor, byWidth);

  // Except that the floor is a preference and the column is not. On an
  // original SE — 320x568, and iOS 14 is still the deployment target — the
  // floor alone leaves the hint panel less room than its chip and rung dots
  // need, and the column overflows the moment a hint opens. There the board
  // is the thing that gives.
  final hardCeiling = constraints.maxHeight -
      gameFixedChromeHeight -
      hintPanelChromeHeight;
  if (size > hardCeiling) size = hardCeiling;
  return size.clamp(0.0, byWidth);
}

/// The smallest board worth playing on: below this a cell is under 29pt and
/// stops being a tap target.
@visibleForTesting
const double boardFloor = 260;

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
        // flushSave, not saveCurrentGame: autosave is debounced, so a plain
        // save here would race the pending timer and the last action before
        // backgrounding would be lost.
        unawaited(context.read<GameCubit>().flushSave());
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
    return MultiBlocListener(
      listeners: [
        // Feedback lives here, not in the cubit. A cubit that reaches for a
        // platform channel cannot be tested without a Flutter binding, and
        // completing a row is a presentation event anyway — the state already
        // says it happened.
        BlocListener<GameCubit, GameState>(
          listenWhen: (prev, curr) =>
              curr.completionFlashCells.isNotEmpty &&
              prev.completionFlashCells != curr.completionFlashCells,
          listener: (_, _) => Haptics.groupComplete(),
        ),
        BlocListener<GameCubit, GameState>(
      listenWhen: (prev, curr) => prev.status != curr.status,
      listener: (context, state) async {
        if (state.status == GameStatus.complete) {
          Haptics.complete();
          // A drill has no score to show — it is one move on a scaffolded
          // position, deliberately not recorded. Sending it to the graded
          // complete screen would report a quality score for something that
          // was never graded.
          if (state.isDrill) {
            await Future<void>.delayed(const Duration(milliseconds: 700));
            if (!context.mounted) return;
            context.go('/learn');
            return;
          }
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
              isImported: state.isImported,
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
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) async {
          if (didPop) return;
          final cubit = context.read<GameCubit>();
          Log.puzzlePaused(
            difficulty: cubit.state.difficulty.name,
            elapsedSeconds: cubit.state.elapsed.inSeconds,
          );
          await cubit.flushSave();
          if (context.mounted) context.go('/home');
        },
        child: Scaffold(
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // The board is sized once, from the space that will still be
                // there when a hint is showing.
                //
                // It used to be Expanded above the hint panel, so the moment
                // a hint appeared the panel took space, the flexible region
                // shrank, and the board moved and resized under the player's
                // finger — while they were reading a sentence about the cells
                // that had just moved. Reserving the panel's height up front
                // means the size is the same whether or not it is on screen,
                // and the flexible gaps absorb the difference instead.
                final board = gameBoardSize(constraints);

                return Column(
                  children: [
                    _GameHeader(),
                    // Fixed, not flexible. All the slack lives below the
                    // board, so the board's top edge is pinned and opening
                    // the hint panel cannot slide it up the screen.
                    const SizedBox(height: 20),
                    SizedBox(
                      width: board,
                      height: board,
                      child: const SudokuGrid(),
                    ),
                    const Spacer(),
                    HintPanel(maxHeight: hintPanelHeightFor(constraints)),
                    const GameToolbar(),
                    const SizedBox(height: AppSpacing.md),
                    const NumberPad(),
                    const SizedBox(height: AppSpacing.lg),
                  ],
                );
              },
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
        return Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
          child: Row(
            children: [
              // back button — paper card
              AppBackButton(
                // Leaving a puzzle is not a plain pop — it saves and routes
                // home, and may ask first.
                label: 'back to home',
                onTap: () async {
                  await context.read<GameCubit>().flushSave();
                  if (context.mounted) context.go('/home');
                },
              ),
              // center — difficulty sticker + timer
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _DifficultySticker(
                      // A drill is about its technique, not its tier. Showing
                      // "hard" on a pointing pair drill names the wrong thing
                      // — the technique is the whole point of being here.
                      difficulty: state.drillTechnique?.singular ??
                          (state.isImported
                              ? 'imported'
                              : state.difficulty.name),
                      col: col,
                    ),
                    // Which daily, when it is not today's. The archive can
                    // hand over any of ninety, and the tier alone does not
                    // say which one you picked.
                    if (state.archiveDate case final date?) ...[
                      const SizedBox(height: 3),
                      Text(
                        DateFormat('EEE d MMM').format(date).toLowerCase(),
                        style: AppTypography.labelSmall
                            .copyWith(color: col.ink3, fontSize: 10),
                      ),
                    ],
                    if (state.showTimer) ...[
                      const SizedBox(height: 4),
                      Text(
                        clockTime(state.elapsed.inSeconds),
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
/// Shown when a floor-targeted tier could not be built inside its budget.
///
/// Says so plainly rather than substituting an easier puzzle, and offers to
/// try again — the search is random, so a second run usually succeeds.
class _GenerationFailed extends StatelessWidget {
  const _GenerationFailed({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'couldn\'t build that one.',
                style: AppTypography.heading.copyWith(color: col.ink),
              ),
              const SizedBox(height: 8),
              Text(
                'puzzles at this tier are rare, and the search came up empty. '
                'trying again usually works.',
                style: AppTypography.body
                    .copyWith(color: col.ink3, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Tappable(
                    label: 'try again',
                    hint: 'the search is random, so a second run usually works',
                    onTap: onRetry,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      decoration: BoxDecoration(
                        color: col.accent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: col.ink, width: 2),
                        boxShadow: col.cardShadow,
                      ),
                      child: Text(
                        'try again',
                        style: AppTypography.body.copyWith(
                          color: col.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Tappable(
                    label: 'back to home',
                    onTap: () => context.go('/home'),
                    child: Text(
                      'back',
                      style: AppTypography.body
                          .copyWith(color: col.ink3, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AsyncGameLoader extends StatefulWidget {
  final Difficulty difficulty;
  final bool isDaily;
  final DateTime? dailyDate;
  final Technique? drillTechnique;
  final Repositories repos;

  const _AsyncGameLoader({
    required this.difficulty,
    required this.isDaily,
    required this.dailyDate,
    required this.drillTechnique,
    required this.repos,
  });

  @override
  State<_AsyncGameLoader> createState() => _AsyncGameLoaderState();
}

class _AsyncGameLoaderState extends State<_AsyncGameLoader> {
  GameCubit? _cubit;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    if (_failed) setState(() => _failed = false);
    final GameCubit? cubit;
    try {
      if (widget.drillTechnique case final technique?) {
        cubit = await GameCubit.trainerAsync(
            repos: widget.repos, technique: technique);
      } else if (widget.isDaily) {
        cubit = await GameCubit.dailyAsync(
            repos: widget.repos, date: widget.dailyDate ?? todayUtc());
      } else {
        cubit = await GameCubit.newGameAsync(
            repos: widget.repos, difficulty: widget.difficulty);
      }
      if (cubit == null) {
        if (mounted) setState(() => _failed = true);
        return;
      }
    } catch (e) {
      // The deep tiers are floor-targeted, so generation can genuinely come
      // up empty inside its attempt budget. Falling back to an easier puzzle
      // would hand someone who asked for a fish a puzzle without one, which
      // is the only thing that tier promises.
      Log.warn('generation failed for ${widget.difficulty.name}: $e',
          tag: 'game');
      if (mounted) setState(() => _failed = true);
      return;
    }
    if (!mounted) {
      cubit.close();
      return;
    }
    final ready = cubit;
    setState(() => _cubit = ready..startTimer());
  }

  @override
  void dispose() {
    _cubit?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    if (_failed) return _GenerationFailed(onRetry: _generate);
    if (cubit == null) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const GridLoader(),
              if (widget.difficulty.isDeep || widget.drillTechnique != null) ...[
                const SizedBox(height: 20),
                Text(
                  widget.drillTechnique != null
                      ? 'building a ${widget.drillTechnique!.singular}.'
                      : 'building one that ${widget.difficulty.description}.',
                  style: AppTypography.labelSmall
                      .copyWith(color: context.appColors.ink4, fontSize: 11),
                ),
              ],
            ],
          ),
        ),
      );
    }
    return BlocProvider.value(value: cubit, child: const _GameView());
  }
}

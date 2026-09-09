import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';

/// The personal-best pace indicator, and the second it used to miss.
///
/// It tested `elapsed == halfway`, checked only from the tick. That is fine
/// while the clock counts one second at a time — and wrong the moment it does
/// not. Resuming restores `elapsed` straight to the saved value, so a puzzle
/// picked up after the halfway mark stepped over the trigger and the
/// indicator could never appear again for that puzzle.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  test('it still fires on a puzzle resumed past the halfway mark', () async {
    // A best time to beat. Halfway is 300s.
    await repos.records.saveRecord(PuzzleRecordsCompanion(
      puzzleId: const Value('old'),
      difficulty: const Value('easy'),
      timeSeconds: const Value(600),
      completedAt: Value(DateTime.now()),
    ));

    final generated =
        SudokuGenerator().generate(difficulty: Difficulty.easy, seed: 9);
    final puzzle = generated.puzzle.toFlatString().split(',').map(int.parse).toList();
    final solution =
        generated.solution.toFlatString().split(',').map(int.parse).toList();

    // Well past 40% of the empties filled, and well past halfway on the clock.
    final board = List<int>.from(puzzle);
    final empties = [for (var i = 0; i < 81; i++) if (puzzle[i] == 0) i];
    for (var i = 0; i < (empties.length * 0.8).floor(); i++) {
      board[empties[i]] = solution[empties[i]];
    }

    await repos.savedGames.saveGame(SavedGamesCompanion.insert(
      puzzleId: 'resumed',
      difficulty: 'easy',
      isDaily: false,
      givenCells: puzzle.join(','),
      solutionCells: solution.join(','),
      boardCells: board.join(','),
      notes: '{}',
      elapsedSeconds: 421, // past 300, and not equal to it
      hintsRemaining: 0,
      mistakeCount: 0,
      isNotesMode: false,
      savedAt: DateTime.now(),
      history: const Value(''),
    ));

    final saved = (await repos.savedGames.getSavedGames()).other!;
    // `startTimer` is what loads the best time and the stuck threshold —
    // the app always does this immediately after `fromSaved`.
    final cubit = GameCubit.fromSaved(saved, repos)..startTimer();
    await cubit.readyForTesting;
    await Future<void>.delayed(Duration.zero);

    expect(cubit.state.isOnPbPace, isFalse, reason: 'nothing has ticked yet');

    cubit.tickForTesting();

    expect(cubit.state.isOnPbPace, isTrue,
        reason: 'the clock is past halfway and the board is ahead of pace — '
            'testing for one exact second means resuming skips it forever');
    await cubit.close();
  });
}

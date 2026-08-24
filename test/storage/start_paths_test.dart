import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';

/// There is one non-daily save slot, so every path that starts a non-daily
/// game has to ask before it takes it.
///
/// Home and the daily calendar always did. The tier pages and the importer
/// were added later and did not, so tapping "play a fish puzzle" or playing
/// an imported grid destroyed a half-finished puzzle without a word. This
/// pins the shape of the problem rather than the prompt: a start path that
/// forgets to ask will silently replace the row below.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });
  tearDown(() async => db.close());

  Future<void> saveOne(String id, {int seconds = 1500}) =>
      repos.savedGames.saveGame(SavedGamesCompanion.insert(
        puzzleId: id,
        difficulty: 'hard',
        isDaily: false,
        givenCells: '0' * 81,
        solutionCells: '1' * 81,
        boardCells: '0' * 81,
        notes: '{}',
        elapsedSeconds: seconds,
        hintsRemaining: 0,
        mistakeCount: 0,
        isNotesMode: false,
        savedAt: DateTime.now(),
      ));

  test('a new non-daily game does take the slot, so asking is the only guard',
      () async {
    await saveOne('the-one-i-was-playing');

    final cubit = (await GameCubit.newGameAsync(
        repos: repos, difficulty: Difficulty.medium))!;
    final empty = List.generate(81, (i) => i).firstWhere((i) =>
        !cubit.state.givenCells.contains(i) &&
        cubit.state.board.get(i ~/ 9, i % 9) == 0);
    cubit.selectCell(empty ~/ 9, empty % 9);
    cubit.placeNumber(cubit.state.solution.get(empty ~/ 9, empty % 9));
    await cubit.flushSave();

    final after = (await repos.savedGames.getSavedGames()).other;
    expect(after?.puzzleId, isNot('the-one-i-was-playing'),
        reason: 'if this ever stops being true the guard is unnecessary — '
            'until then every start path must ask');
    await cubit.close();
  });

  test('the daily slot is untouched by it', () async {
    await repos.savedGames.saveGame(SavedGamesCompanion.insert(
      puzzleId: '2026-08-03',
      difficulty: 'hard',
      isDaily: true,
      givenCells: '0' * 81,
      solutionCells: '1' * 81,
      boardCells: '0' * 81,
      notes: '{}',
      elapsedSeconds: 60,
      hintsRemaining: 0,
      mistakeCount: 0,
      isNotesMode: false,
      savedAt: DateTime.now(),
    ));
    await saveOne('casual');

    final cubit = (await GameCubit.newGameAsync(
        repos: repos, difficulty: Difficulty.easy))!;
    await cubit.flushSave();

    final now = await repos.savedGames.getSavedGames();
    expect(now.daily?.puzzleId, '2026-08-03',
        reason: 'a casual game must never reach across to the daily');
    await cubit.close();
  });
}

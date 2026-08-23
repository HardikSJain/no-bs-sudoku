import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';

/// An imported puzzle is an analysis tool, not a scored mode.
///
/// It has no difficulty, so no par time, so no quality score. Recording one
/// would put an invented grade into exactly the data the timing and quality
/// work existed to repair — the same reason a technique drill is not
/// recorded either.
void main() {
  late AppDatabase db;
  late Repositories repos;
  final generator = SudokuGenerator();

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  Future<GameCubit> playToCompletion() async {
    final g = generator.generate(difficulty: Difficulty.easy, seed: 12);
    final cubit = GameCubit.imported(
      repos: repos,
      puzzle: g.puzzle,
      solution: g.solution,
    );
    for (int i = 0; i < 81; i++) {
      if (cubit.state.board.get(i ~/ 9, i % 9) != 0) continue;
      cubit.selectCell(i ~/ 9, i % 9);
      cubit.placeNumber(g.solution.get(i ~/ 9, i % 9));
    }
    await cubit.saveComplete;
    return cubit;
  }

  group('it plays like a normal puzzle', () {
    test('the grid and its givens come through intact', () {
      final g = generator.generate(difficulty: Difficulty.medium, seed: 4);
      final cubit = GameCubit.imported(
        repos: repos,
        puzzle: g.puzzle,
        solution: g.solution,
      );
      addTearDown(cubit.close);

      expect(cubit.state.isImported, isTrue);
      expect(cubit.state.board, g.puzzle);
      expect(cubit.state.solution, g.solution);
      for (int i = 0; i < 81; i++) {
        final filled = g.puzzle.get(i ~/ 9, i % 9) != 0;
        expect(cubit.state.isGiven(i ~/ 9, i % 9), filled, reason: 'cell $i');
      }
    });

    test('and it can be completed', () async {
      final cubit = await playToCompletion();
      addTearDown(cubit.close);
      expect(cubit.state.status, GameStatus.complete);
    });
  });

  group('but it is never graded', () {
    test('finishing one writes no record', () async {
      final cubit = await playToCompletion();
      addTearDown(cubit.close);
      expect(await repos.records.getRecordCount(), 0,
          reason: 'an imported grid has no par time, so any quality score '
              'recorded for it would be invented');
    });

    test('and moves no streak', () async {
      final before = await repos.profiles.getProfile();
      final cubit = await playToCompletion();
      addTearDown(cubit.close);

      final after = await repos.profiles.getProfile();
      expect(after.currentStreak, before.currentStreak);
      expect(after.totalSolved, before.totalSolved);
    });

    test('isScored is false for imports and drills alike', () {
      final g = generator.generate(difficulty: Difficulty.easy, seed: 1);
      final imported = GameCubit.imported(
        repos: repos,
        puzzle: g.puzzle,
        solution: g.solution,
      );
      addTearDown(imported.close);
      expect(imported.state.isScored, isFalse);

      final normal =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 1);
      addTearDown(normal.close);
      expect(normal.state.isScored, isTrue);
    });
  });
}

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';

/// Giving up on a puzzle.
///
/// Reported by a player: "there is no way to abandon a puzzle... I am forced
/// to complete the puzzle." They were right in the way that matters — backing
/// out *saved*, so the puzzle came home, took the one slot, and the next new
/// game opened with a prompt about it. Every exit preserved the thing they
/// wanted rid of.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  GameCubit newGame() =>
      GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 7);

  int firstEmpty(GameCubit c) => List.generate(81, (i) => i).firstWhere((i) =>
      !c.state.givenCells.contains(i) && c.state.board.get(i ~/ 9, i % 9) == 0);

  group('an empty board leaves without ceremony', () {
    test('a puzzle nobody touched has no progress to ask about', () {
      final cubit = newGame();
      expect(cubit.state.hasProgress, isFalse);
      cubit.close();
    });

    test('one digit is enough to count', () {
      final cubit = newGame();
      final i = firstEmpty(cubit);
      cubit.selectCell(i ~/ 9, i % 9);
      cubit.placeNumber(cubit.state.solution.get(i ~/ 9, i % 9));
      expect(cubit.state.hasProgress, isTrue);
      cubit.close();
    });

    test('and so is one pencil mark', () {
      final cubit = newGame();
      final i = firstEmpty(cubit);
      cubit.selectCell(i ~/ 9, i % 9);
      cubit.toggleNotesMode();
      cubit.placeNumber(5);
      expect(cubit.state.hasProgress, isTrue,
          reason: 'notes are work too, and losing them silently is the same '
              'loss as losing a digit');
      cubit.close();
    });
  });

  group('giving up', () {
    test('throws the save away rather than leaving it to be asked about later',
        () async {
      final cubit = newGame();
      final i = firstEmpty(cubit);
      cubit.selectCell(i ~/ 9, i % 9);
      cubit.placeNumber(cubit.state.solution.get(i ~/ 9, i % 9));
      await cubit.flushSave();

      expect((await repos.savedGames.getSavedGames()).other, isNotNull,
          reason: 'the puzzle is on the slot before giving up');

      await cubit.giveUp();

      expect(cubit.state.status, GameStatus.abandoned);
      expect((await repos.savedGames.getSavedGames()).other, isNull,
          reason: 'the whole point is that it does not follow you home');
      await cubit.close();
    });

    test('writes no record and moves no streak', () async {
      final before = await repos.profiles.getProfile();
      final cubit = newGame();
      final i = firstEmpty(cubit);
      cubit.selectCell(i ~/ 9, i % 9);
      cubit.placeNumber(cubit.state.solution.get(i ~/ 9, i % 9));

      await cubit.giveUp();

      expect(await repos.records.getAllRecords(), isEmpty,
          reason: 'quitting is allowed, not scored');
      final after = await repos.profiles.getProfile();
      expect(after.currentStreak, before.currentStreak);
      await cubit.close();
    });

    test('is not something a finished puzzle can do', () async {
      final cubit = newGame();
      await cubit.giveUp();
      expect(cubit.state.status, GameStatus.abandoned);
      // Second call is a no-op rather than a second abandon.
      await cubit.giveUp();
      expect(cubit.state.status, GameStatus.abandoned);
      await cubit.close();
    });
  });
}

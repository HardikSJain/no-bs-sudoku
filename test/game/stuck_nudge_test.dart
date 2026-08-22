import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/hint_engine.dart';

void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  /// Advances the cubit's clock without waiting for real seconds.
  Future<void> idle(GameCubit cubit, int seconds) async {
    for (int i = 0; i < seconds; i++) {
      cubit.tickForTesting();
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('unprompted help is free', () {
    test('a nudge costs nothing against quality', () async {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await cubit.readyForTesting;

      await idle(cubit, 95);

      expect(cubit.state.hasHint, isTrue,
          reason: 'a stalled player should be offered the first rung');
      expect(cubit.state.hintWasUnprompted, isTrue);
      expect(cubit.state.hintDepthTotal, 0,
          reason: 'charging for help nobody asked for is indefensible');
      expect(cubit.state.hintsUsed, 0);
      await cubit.close();
    });

    test('but taking it further starts paying from scratch', () async {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await cubit.readyForTesting;
      await idle(cubit, 95);
      expect(cubit.state.hintWasUnprompted, isTrue);

      cubit.useHint();

      expect(cubit.state.hintRung, HintRung.narrow);
      expect(cubit.state.hintWasUnprompted, isFalse);
      expect(cubit.state.hintDepthTotal, HintRung.narrow.cost,
          reason: 'the free rung must not discount the paid one');
      expect(cubit.state.hintsUsed, 1);
      await cubit.close();
    });
  });

  group('it does not nag', () {
    test('nothing fires before the floor, however slow the player', () async {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await cubit.readyForTesting;

      await idle(cubit, 40);
      expect(cubit.state.hasHint, isFalse,
          reason: 'a prompt this early is an interruption, not help');
      await cubit.close();
    });

    test('it stops after three and does not come back', () async {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await cubit.readyForTesting;

      for (int round = 0; round < 5; round++) {
        await idle(cubit, 95);
        if (!cubit.state.hasHint) break;
        cubit.dismissHint();
        // A placement is what re-arms it.
        final step = cubit.state.activeHint;
        expect(step, isNull);
        cubit.selectCell(_firstEmptyRow(cubit), _firstEmptyCol(cubit));
        cubit.placeNumber(cubit.state.solution
            .get(_firstEmptyRow(cubit), _firstEmptyCol(cubit)));
      }

      await idle(cubit, 200);
      expect(cubit.state.hasHint, isFalse,
          reason: 'past three nudges it stops being help and starts being '
              'the app playing for you');
      await cubit.close();
    });

    test('it waits for a placement before offering again', () async {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await cubit.readyForTesting;

      await idle(cubit, 95);
      expect(cubit.state.hasHint, isTrue);
      cubit.dismissHint();

      // Sitting and thinking, having placed nothing, must not re-trigger it.
      await idle(cubit, 200);
      expect(cubit.state.hasHint, isFalse);
      await cubit.close();
    });

    test('the switch turns it off entirely', () async {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await cubit.readyForTesting;
      cubit.setNudgeWhenStuck(false);

      await idle(cubit, 300);
      expect(cubit.state.hasHint, isFalse);
      await cubit.close();
    });
  });

  group('the threshold ignores untrustworthy timing', () {
    test('records without the timing marker are not pooled', () async {
      // A single wall-clock record contributed a gap of hours. Pooling it
      // would push the personal p90 so high the nudge could never fire.
      await db.customInsert(
        "INSERT INTO puzzle_records "
        "(puzzle_id, difficulty, time_seconds, completed_at, solve_times, timing_version) "
        "VALUES ('a', 'easy', 100, 0, '28800,28800,28800', 1)",
      );
      expect(await repos.records.trustedSolveTimeDeltas('easy'), isEmpty);
      expect(await repos.records.trustedRecordCount('easy'), 0);
    });

    test('records with the marker are pooled', () async {
      await db.customInsert(
        "INSERT INTO puzzle_records "
        "(puzzle_id, difficulty, time_seconds, completed_at, solve_times, timing_version) "
        "VALUES ('b', 'easy', 100, 0, '5,9,12', 2)",
      );
      expect(await repos.records.trustedSolveTimeDeltas('easy'), [5, 9, 12]);
      expect(await repos.records.trustedRecordCount('easy'), 1);
    });
  });
}

int _firstEmptyRow(GameCubit c) {
  for (int i = 0; i < 81; i++) {
    if (c.state.board.get(i ~/ 9, i % 9) == 0) return i ~/ 9;
  }
  return 0;
}

int _firstEmptyCol(GameCubit c) {
  for (int i = 0; i < 81; i++) {
    if (c.state.board.get(i ~/ 9, i % 9) == 0) return i % 9;
  }
  return 0;
}

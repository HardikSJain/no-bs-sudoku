import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/hint_engine.dart';

/// The first rung has to put something on the board.
///
/// It did not, and no test noticed, because every hint test asked what the
/// engine *found* rather than what the grid then *showed*. A naked single
/// carries no unit — its proof is the filled peers — so `hintUnitCells`
/// returned nothing while the copy underneath said "there's something in box
/// 1". The commonest hint in the app pointed at an unchanged board, which is
/// why the first press read as a button that did not work, and why people
/// pressed it until the fourth press filled the answer in.
///
/// Found by running the app. Pinned here so it cannot come back quietly.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  test('the locate rung marks the board, for every difficulty', () async {
    for (final difficulty in Difficulty.classic) {
      final cubit =
          GameCubit.newGame(repos: repos, difficulty: difficulty, seed: 11);
      final result = cubit.useHint();

      expect(result, isA<HintStep>(),
          reason: '${difficulty.name}: a fresh puzzle has a next step');
      expect(cubit.state.hintRung, HintRung.locate);
      expect(cubit.state.hintUnitCells, isNotEmpty,
          reason: '${difficulty.name}: the first rung says "there is '
              'something in box N" — the board has to show which N, or the '
              'app looks like it ignored the tap');
      await cubit.close();
    }
  });

  test('a naked single is the case that used to point at nothing', () async {
    // The technique with no unit of its own. Named explicitly because it is
    // the commonest hint and the one the bug actually hit.
    final cubit =
        GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 11);

    var found = false;
    for (var step = 0; step < 30 && !found; step++) {
      final result = cubit.useHint();
      if (result is! HintStep) break;
      if (result.deduction.technique == Technique.nakedSingle) {
        found = true;
        expect(cubit.state.hintRung, HintRung.locate);
        expect(cubit.state.hintUnitCells, isNotEmpty,
            reason: 'a naked single carries no unit, so the board has to '
                'derive the box the copy names');
        expect(cubit.state.hintUnitCells.length, 9,
            reason: 'the derived unit is a box');
        break;
      }
      // Not the one we are after: escalate to the apply rung, which places
      // the digit, so the next request finds a different step.
      while (!cubit.state.hintRung.isLast) {
        cubit.useHint();
      }
    }
    expect(found, isTrue, reason: 'an easy puzzle contains a naked single');
    await cubit.close();
  });

  test('the shading is the sole cue only while it is the only cue', () async {
    final cubit =
        GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 11);
    cubit.useHint();
    expect(cubit.state.hintUnitIsSoleCue, isTrue,
        reason: 'at locate there is no target yet, so the shading is the hint');

    cubit.useHint();
    expect(cubit.state.hintRung, HintRung.narrow);
    expect(cubit.state.hintUnitIsSoleCue, isFalse,
        reason: 'once a cell is picked out in solid sun the unit is context '
            'behind it, and must not compete with it');
    await cubit.close();
  });
}

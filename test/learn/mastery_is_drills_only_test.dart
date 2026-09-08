import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/learn/mastery.dart';

/// Mastery is measured from drills and nothing else.
///
/// That claim is the whole reason the levels mean anything — "spotted it
/// unaided" is not observable in ordinary play, where a hint writes pencil
/// marks, note actions carry no attribution, and one wrong digit makes every
/// later step unreadable. `TechniqueMastery` says so in its own doc.
///
/// It was never pinned. Checked here after a library page showed "learning"
/// against a technique in a session where it looked like nothing had been
/// drilled — it turned out a drill had been run, but the invariant should not
/// depend on remembering what you tapped.
void main() {
  test('a solve driven entirely by hints records no drills at all', () async {
    final db = AppDatabase.forTesting(NativeDatabase.memory());
    final repos = Repositories(db);
    addTearDown(db.close);

    final cubit =
        GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 3);

    // The most assisted play possible: ask, escalate, let it place the digit,
    // repeat. Every technique the engine names along the way is "assisted".
    for (var i = 0; i < 60; i++) {
      cubit.useHint();
    }
    await Future<void>.delayed(Duration.zero);

    final profile = await repos.mastery.getProfile();
    for (final entry in profile.byTechnique.entries) {
      expect(entry.value.drillsAttempted, 0,
          reason: '${entry.key.name}: being shown a technique is not '
              'practising it');
      expect(entry.value.drillsUnaided, 0,
          reason: '${entry.key.name}: and certainly not practising it '
              'unaided');
      expect(entry.value.level, isNot(MasteryLevel.learning),
          reason: '${entry.key.name}: "learning" claims a drill happened');
      expect(entry.value.level, isNot(MasteryLevel.practised));
      expect(entry.value.level, isNot(MasteryLevel.mastered));
    }
    await cubit.close();
  });
}

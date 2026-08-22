import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';
import 'package:no_bs_sudoku/features/game/hint_engine.dart';

void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('GameCubit.newGame', () {
    test('creates a valid game state', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.difficulty, Difficulty.easy);
      expect(cubit.state.hintsUsed, 0);
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.isDaily, false);
      expect(cubit.state.givenCells.isNotEmpty, true);
      cubit.close();
    });

    test('seeded generation is deterministic', () {
      final cubit1 = GameCubit.newGame(repos: repos, difficulty: Difficulty.medium, seed: 123);
      final cubit2 = GameCubit.newGame(repos: repos, difficulty: Difficulty.medium, seed: 123);
      expect(cubit1.state.puzzle, cubit2.state.puzzle);
      expect(cubit1.state.solution, cubit2.state.solution);
      cubit1.close();
      cubit2.close();
    });
  });

  group('GameCubit.daily', () {
    test('creates a daily game', () {
      final cubit = GameCubit.daily(repos: repos, date: DateTime(2025, 3, 10)); // Monday = easy
      expect(cubit.state.isDaily, true);
      expect(cubit.state.difficulty, Difficulty.easy);
      cubit.close();
    });
  });

  group('Cell selection', () {
    test('selectCell updates state', () {
      final cubit = GameCubit.newGame(repos: repos, seed: 1);
      cubit.selectCell(0, 0);
      expect(cubit.state.selectedRow, 0);
      expect(cubit.state.selectedCol, 0);
      expect(cubit.state.hasSelection, true);
      cubit.close();
    });
  });

  group('Place number', () {
    test('placing correct number updates board', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      // Find an empty cell
      int? emptyRow, emptyCol;
      for (int r = 0; r < 9 && emptyRow == null; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }
      expect(emptyRow, isNotNull);

      final correctValue = cubit.state.solution.get(emptyRow!, emptyCol!);
      cubit.selectCell(emptyRow, emptyCol);
      cubit.placeNumber(correctValue);

      expect(cubit.state.board.get(emptyRow, emptyCol), correctValue);
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.history.length, 1);
      cubit.close();
    });

    test('placing wrong number increments mistakes', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      int? emptyRow, emptyCol;
      for (int r = 0; r < 9 && emptyRow == null; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      final correctValue = cubit.state.solution.get(emptyRow!, emptyCol!);
      final wrongValue = correctValue == 9 ? 1 : correctValue + 1;

      cubit.selectCell(emptyRow, emptyCol);
      cubit.placeNumber(wrongValue);

      expect(cubit.state.mistakeCount, 1);
      cubit.close();
    });

    test('placing on given cell is no-op', () {
      final cubit = GameCubit.newGame(repos: repos, seed: 1);
      final givenIdx = cubit.state.givenCells.first;
      final row = givenIdx ~/ 9;
      final col = givenIdx % 9;

      cubit.selectCell(row, col);
      cubit.placeNumber(5);

      expect(cubit.state.history, isEmpty);
      cubit.close();
    });
  });

  group('Undo', () {
    test('undo reverts placement', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      int? emptyRow, emptyCol;
      for (int r = 0; r < 9 && emptyRow == null; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      final correctValue = cubit.state.solution.get(emptyRow!, emptyCol!);
      cubit.selectCell(emptyRow, emptyCol);
      cubit.placeNumber(correctValue);
      expect(cubit.state.board.get(emptyRow, emptyCol), correctValue);

      cubit.undo();
      expect(cubit.state.board.get(emptyRow, emptyCol), 0);
      expect(cubit.state.history, isEmpty);
      cubit.close();
    });

    test('undo with empty history is no-op', () {
      final cubit = GameCubit.newGame(repos: repos, seed: 1);
      cubit.undo(); // should not throw
      expect(cubit.state.history, isEmpty);
      cubit.close();
    });
  });

  group('Resume fidelity', () {
    /// Plays a few moves, saves, and restores from the persisted row.
    Future<(GameCubit original, GameCubit restored)> playAndRestore() async {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      final empties = <(int, int)>[];
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) empties.add((r, c));
        }
      }

      // Two correct placements, one wrong, one note.
      for (final (r, c) in empties.take(2)) {
        cubit.selectCell(r, c);
        cubit.placeNumber(cubit.state.solution.get(r, c));
      }
      final (wr, wc) = empties[2];
      final correct = cubit.state.solution.get(wr, wc);
      cubit.selectCell(wr, wc);
      cubit.placeNumber(correct == 9 ? 1 : correct + 1);

      final (nr, nc) = empties[3];
      cubit.selectCell(nr, nc);
      cubit.toggleNotesMode();
      cubit.placeNumber(4);
      cubit.toggleNotesMode();

      await cubit.flushSave();
      final saved = await repos.savedGames.getSavedGame();
      expect(saved, isNotNull);

      return (cubit, GameCubit.fromSaved(saved!, repos));
    }

    test('the undo stack survives a save and restore', () async {
      final (original, restored) = await playAndRestore();
      addTearDown(original.close);
      addTearDown(restored.close);

      // Backgrounding used to destroy this outright — fromSaved restored no
      // history at all.
      expect(restored.state.history, hasLength(original.state.history.length));
      expect(restored.state.history, isNotEmpty);

      // And it actually unwinds rather than just being present. The last
      // action is a note, which changes notes and not the board — so drain the
      // whole stack and check it empties back to the original position.
      final depth = restored.state.history.length;
      for (int i = 0; i < depth; i++) {
        restored.undo();
      }
      expect(restored.state.history, isEmpty);
      expect(
        restored.state.board.toFlatString(),
        restored.state.puzzle.toFlatString(),
        reason: 'undoing everything returns the board to the givens',
      );
    });

    test('velocity counters and techniques survive', () async {
      final (original, restored) = await playAndRestore();
      addTearDown(original.close);
      addTearDown(restored.close);

      // Quality score and velocity analysis were wrong for every resumed
      // puzzle because these all reset to zero.
      expect(restored.solveTimes, original.solveTimes);
      // _techniques was lost too, so a resumed puzzle showed an empty
      // puzzleDna on the complete screen.
      expect(restored.techniques, original.techniques);
      expect(restored.techniques, isNotEmpty);
      expect(restored.state.mistakeCount, original.state.mistakeCount);
    });

    test('a pre-v10 save with no history still restores the board', () async {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 7);
      addTearDown(cubit.close);
      await cubit.flushSave();

      final saved = await repos.savedGames.getSavedGame();
      // Simulate a row written before the resume columns existed.
      final legacy = saved!.copyWith(history: '', placementDeltas: '',
          mistakeCells: '', techniques: '');

      final restored = GameCubit.fromSaved(legacy, repos);
      addTearDown(restored.close);

      expect(restored.state.board.toFlatString(),
          cubit.state.board.toFlatString());
      expect(restored.state.history, isEmpty);
      expect(restored.state.status, GameStatus.playing);
    });

    test('a corrupt history costs the undo stack, never the puzzle', () async {
      final (original, restored0) = await playAndRestore();
      addTearDown(original.close);
      await restored0.close();

      final saved = await repos.savedGames.getSavedGame();
      final corrupt = saved!.copyWith(history: '{ not valid json');

      final restored = GameCubit.fromSaved(corrupt, repos);
      addTearDown(restored.close);

      // The old catch-all deleted the save and handed back a fresh medium
      // game, so one bad field threw away the whole puzzle.
      expect(restored.state.difficulty, Difficulty.easy);
      expect(restored.state.board.toFlatString(),
          original.state.board.toFlatString());
      expect(restored.state.history, isEmpty);
      expect(await repos.savedGames.getSavedGame(), isNotNull,
          reason: 'the save must not be deleted over a bad history blob');
    });
  });

  group('Isolate boundary', () {
    // Guard for the DI migration. newGameAsync and dailyAsync hand a closure to
    // Isolate.run. Today they are static and capture only a Difficulty, so the
    // closure is sendable. The moment generation sits behind an injected
    // collaborator, that closure can capture an object transitively holding a
    // drift AppDatabase and a StreamController — which throws
    // "Illegal argument in isolate message" at RUNTIME ONLY, on the new-game
    // path. The synchronous factories the rest of this file uses would not
    // catch it, and app_database.dart sets shareAcrossIsolates: true, which
    // makes the mistake look plausible.
    test('newGameAsync closure stays sendable', () async {
      final cubit = await GameCubit.newGameAsync(repos: repos, difficulty: Difficulty.easy);
      addTearDown(cubit.close);

      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.difficulty, Difficulty.easy);
      expect(cubit.state.givenCells, isNotEmpty);
      expect(cubit.techniques, isNotEmpty);
    });

    test('dailyAsync closure stays sendable', () async {
      final cubit = await GameCubit.dailyAsync(repos: repos, date: DateTime.utc(2026, 8, 22));
      addTearDown(cubit.close);

      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.isDaily, true);
      expect(cubit.state.puzzleId, '2026-08-22');
    });
  });

  group('R0 defect regressions', () {
    test('useHint with no selection still gives a hint', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      expect(cubit.state.hasSelection, false);

      // The reported bug: this used to return silently while the toolbar
      // reported itself enabled and buzzed before calling. There is now
      // always a next nudge.
      final result = cubit.useHint();

      expect(result, isA<HintStep>());
      expect(cubit.state.activeHint, isNotNull);
      expect(cubit.state.hintRung, HintRung.locate);
      expect(cubit.state.board, cubit.state.puzzle,
          reason: 'the first rung locates, it does not fill anything in');
      cubit.close();
    });

    test('four taps walk the rungs and then apply', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      cubit.useHint();
      final pinned = cubit.state.activeHint!;
      expect(cubit.state.hintRung, HintRung.locate);

      cubit.useHint();
      expect(cubit.state.hintRung, HintRung.narrow);
      expect(cubit.state.activeHint, pinned, reason: 'the step must not move');

      cubit.useHint();
      expect(cubit.state.hintRung, HintRung.explain);
      expect(cubit.state.activeHint, pinned);

      final (idx, digit) = pinned.targets.first;
      cubit.useHint();
      expect(cubit.state.board.get(idx ~/ 9, idx % 9), digit);
      cubit.close();
    });

    test('the pinned step does not jump between taps', () {
      // Recomputing per tap would let tap one say box 4 and tap two say box 7.
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.medium, seed: 7);
      cubit.useHint();
      final first = cubit.state.activeHint;
      cubit.useHint();
      cubit.useHint();
      expect(cubit.state.activeHint, first);
      cubit.close();
    });

    test('a given cell falls through rather than refusing', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      int? gr, gc;
      for (int r = 0; r < 9 && gr == null; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.isGiven(r, c)) {
            gr = r;
            gc = c;
            break;
          }
        }
      }
      cubit.selectCell(gr!, gc!);

      expect(cubit.useHint(), isA<HintStep>());
      expect(cubit.state.activeHint, isNotNull);
      cubit.close();
    });

    test('erase with no selection reports that nothing happened', () {
      final cubit = GameCubit.newGame(repos: repos, seed: 42);
      expect(cubit.state.hasSelection, false);
      expect(cubit.erase(), false, reason: 'caller must be able to skip the haptic');
      cubit.close();
    });

    test('undo of a wrong placement gives the mistake back', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      int? r, c;
      for (int i = 0; i < 9 && r == null; i++) {
        for (int j = 0; j < 9; j++) {
          if (cubit.state.board.get(i, j) == 0) {
            r = i;
            c = j;
            break;
          }
        }
      }
      final correct = cubit.state.solution.get(r!, c!);
      final wrong = correct == 9 ? 1 : correct + 1;

      cubit.selectCell(r, c);
      cubit.placeNumber(wrong);
      expect(cubit.state.mistakeCount, 1);

      cubit.undo();

      // Previously the counter only ever climbed, so a taken-back mistake
      // still cost quality score and still counted toward the mistake limit.
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.board.get(r, c), 0);
      cubit.close();
    });

    test('placement timing uses elapsed, not wall clock', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      int? r, c;
      for (int i = 0; i < 9 && r == null; i++) {
        for (int j = 0; j < 9; j++) {
          if (cubit.state.board.get(i, j) == 0) {
            r = i;
            c = j;
            break;
          }
        }
      }
      cubit.selectCell(r!, c!);
      cubit.placeNumber(cubit.state.solution.get(r, c));

      int? r2, c2;
      for (int i = 0; i < 9 && r2 == null; i++) {
        for (int j = 0; j < 9; j++) {
          if (cubit.state.board.get(i, j) == 0) {
            r2 = i;
            c2 = j;
            break;
          }
        }
      }
      cubit.selectCell(r2!, c2!);
      cubit.placeNumber(cubit.state.solution.get(r2, c2));

      // The timer never ticked, so elapsed never advanced. Wall clock would
      // have recorded real milliseconds here — and an overnight backgrounding
      // would have recorded 28800 seconds.
      expect(cubit.solveTimes, isNotEmpty);
      expect(cubit.solveTimes.every((d) => d == 0), true,
          reason: 'deltas come from state.elapsed, which did not advance');
      cubit.close();
    });
  });

  group('Hints', () {
    /// Walks a hint all the way to apply.
    void fullReveal(GameCubit cubit) {
      for (int i = 0; i < HintRung.values.length; i++) {
        cubit.useHint();
      }
    }

    test('a full escalation places the right digit', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.useHint();
      final (idx, digit) = cubit.state.activeHint!.targets.first;
      expect(digit, cubit.state.solution.get(idx ~/ 9, idx % 9));

      cubit.useHint();
      cubit.useHint();
      cubit.useHint();
      expect(cubit.state.board.get(idx ~/ 9, idx % 9), digit);
      cubit.close();
    });

    test('hints never run out', () {
      // The old cap left a stuck player with a dead button. Depth is the
      // cost now, not scarcity.
      final cubit = GameCubit.newGame(repos: repos, seed: 42);
      for (int i = 0; i < 10; i++) {
        fullReveal(cubit);
      }
      expect(cubit.state.hintsUsed, greaterThanOrEqualTo(10));
      expect(cubit.useHint(), isNot(isA<HintNothing>()));
      cubit.close();
    });

    test('a gentle nudge costs far less than a reveal', () {
      final nudged = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      nudged.useHint();
      final nudgeCost = nudged.state.hintDepthTotal;
      nudged.close();

      final revealed = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      fullReveal(revealed);
      final revealCost = revealed.state.hintDepthTotal;
      revealed.close();

      expect(nudgeCost, HintRung.locate.cost);
      expect(revealCost, HintRung.apply.cost);
      expect(nudgeCost * 5, lessThan(revealCost * 2),
          reason: 'five nudges must still beat two reveals, or the gradient '
              'is decorative');
    });

    test('escalating one hint replaces its cost, it does not stack', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.useHint();
      cubit.useHint();
      cubit.useHint();
      // locate + narrow + explain must be 3, not 1 + 2 + 3.
      expect(cubit.state.hintDepthTotal, HintRung.explain.cost);
      expect(cubit.state.hintsUsed, 1);
      cubit.close();
    });

    test('undo of an applied hint restores the board and the accounting', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.useHint();
      cubit.useHint();
      cubit.useHint();
      final depthAtExplain = cubit.state.hintDepthTotal;
      final (idx, _) = cubit.state.activeHint!.targets.first;

      cubit.useHint();
      expect(cubit.state.board.get(idx ~/ 9, idx % 9), isNot(0));

      cubit.undo();
      expect(cubit.state.board.get(idx ~/ 9, idx % 9), 0);
      expect(cubit.state.hintDepthTotal, depthAtExplain,
          reason: 'undo must roll the depth back to where the rung was');
      expect(cubit.state.hintRung, HintRung.explain);
      cubit.close();
    });

    test('with explanations off the button answers in one tap', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.setHintsExplain(false);

      cubit.useHint();
      expect(cubit.state.hintRung, HintRung.apply);
      expect(cubit.state.hintDepthTotal, HintRung.apply.cost,
          reason: 'skipping to the answer costs the full reveal');
      expect(cubit.state.board, isNot(cubit.state.puzzle));
      cubit.close();
    });

    test('a wrong digit is reported before any technique', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      int? r, c;
      for (int i = 0; i < 81 && r == null; i++) {
        if (cubit.state.board.get(i ~/ 9, i % 9) == 0) {
          r = i ~/ 9;
          c = i % 9;
        }
      }
      final truth = cubit.state.solution.get(r!, c!);
      cubit.selectCell(r, c);
      cubit.placeNumber(truth == 9 ? 1 : truth + 1);

      final result = cubit.useHint();
      expect(result, isA<HintWrongDigit>());
      expect((result as HintWrongDigit).cells, contains(r * 9 + c));
      cubit.close();
    });
  });

  group('Notes', () {
    test('toggle notes mode', () {
      final cubit = GameCubit.newGame(repos: repos, seed: 1);
      expect(cubit.state.isNotesMode, false);
      cubit.toggleNotesMode();
      expect(cubit.state.isNotesMode, true);
      cubit.toggleNotesMode();
      expect(cubit.state.isNotesMode, false);
      cubit.close();
    });

    test('place note in notes mode', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.toggleNotesMode();

      int? emptyRow, emptyCol;
      for (int r = 0; r < 9 && emptyRow == null; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      cubit.selectCell(emptyRow!, emptyCol!);
      cubit.placeNumber(1);
      cubit.placeNumber(5);

      final notes = cubit.state.notesAt(emptyRow, emptyCol);
      expect(notes.contains(1), true);
      expect(notes.contains(5), true);
      cubit.close();
    });
  });

  group('Erase', () {
    test('erase removes value from cell', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      int? emptyRow, emptyCol;
      for (int r = 0; r < 9 && emptyRow == null; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            emptyRow = r;
            emptyCol = c;
            break;
          }
        }
      }

      final value = cubit.state.solution.get(emptyRow!, emptyCol!);
      cubit.selectCell(emptyRow, emptyCol);
      cubit.placeNumber(value);
      expect(cubit.state.board.get(emptyRow, emptyCol), value);

      cubit.erase();
      expect(cubit.state.board.get(emptyRow, emptyCol), 0);
      cubit.close();
    });
  });

  group('Techniques', () {
    test('techniques are computed for new game', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      expect(cubit.techniques, isNotEmpty);
      cubit.close();
    });
  });

  group('Mistake limit', () {
    // Helper: make N wrong placements on a fresh cubit (limit must be off/0)
    void makeMistakes(GameCubit cubit, int count) {
      int made = 0;
      for (int r = 0; r < 9 && made < count; r++) {
        for (int c = 0; c < 9 && made < count; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            final correct = cubit.state.solution.get(r, c);
            final wrong = correct == 9 ? 1 : correct + 1;
            cubit.selectCell(r, c);
            cubit.placeNumber(wrong);
            made++;
          }
        }
      }
    }

    test('hitting mistake limit during play emits abandoned', () async {
      await repos.preferences.updatePreferences(
        GamePreferencesTableCompanion(mistakeLimit: const Value(3)),
      );

      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      cubit.startTimer();
      await Future.delayed(const Duration(milliseconds: 50));

      makeMistakes(cubit, 2);
      expect(cubit.state.status, GameStatus.playing);

      makeMistakes(cubit, 1); // 3rd mistake hits the limit
      // Let the unawaited deleteSavedGame() complete before DB tearDown
      await Future.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.status, GameStatus.abandoned);
      expect(cubit.state.mistakeCount, 3);

      await cubit.close();
    });

    test('resuming with mistakes already at limit immediately abandons', () async {
      // Original game: limit off, accumulate 3 mistakes, save
      final original = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      makeMistakes(original, 3);
      expect(original.state.mistakeCount, 3);
      await original.saveCurrentGame();
      await original.close();

      // Now enable the limit at 3
      await repos.preferences.updatePreferences(
        GamePreferencesTableCompanion(mistakeLimit: const Value(3)),
      );

      final saved = await repos.savedGames.getSavedGame();
      expect(saved, isNotNull);

      final resumed = GameCubit.fromSaved(saved!, repos);
      resumed.startTimer();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(resumed.state.status, GameStatus.abandoned);
      await resumed.close();
    });

    test('resuming with mistakes below limit stays playing', () async {
      final original = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      makeMistakes(original, 2);
      expect(original.state.mistakeCount, 2);
      await original.saveCurrentGame();
      await original.close();

      await repos.preferences.updatePreferences(
        GamePreferencesTableCompanion(mistakeLimit: const Value(3)),
      );

      final saved = await repos.savedGames.getSavedGame();
      final resumed = GameCubit.fromSaved(saved!, repos);
      resumed.startTimer();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(resumed.state.status, GameStatus.playing);
      expect(resumed.state.mistakeCount, 2);
      await resumed.close();
    });

    test('resuming with limit off ignores mistake count', () async {
      final original = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      makeMistakes(original, 5);
      await original.saveCurrentGame();
      await original.close();

      // mistakeLimit stays 0 (off) — no update needed, default is 0

      final saved = await repos.savedGames.getSavedGame();
      final resumed = GameCubit.fromSaved(saved!, repos);
      resumed.startTimer();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(resumed.state.status, GameStatus.playing);
      await resumed.close();
    });
  });
}

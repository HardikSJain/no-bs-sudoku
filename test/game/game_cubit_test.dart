import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';

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
      expect(cubit.state.hintsRemaining, 3);
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
    test('useHint with no selection selects a cell and spends nothing', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);
      expect(cubit.state.hasSelection, false);

      final spent = cubit.useHint();

      // The reported bug: this used to return silently while the toolbar
      // reported itself enabled and buzzed before calling.
      expect(spent, false, reason: 'must not spend a hint on an unpicked cell');
      expect(cubit.state.hasSelection, true, reason: 'must select something');
      expect(cubit.state.hintsRemaining, 3);
      final r = cubit.state.selectedRow!;
      final c = cubit.state.selectedCol!;
      expect(cubit.state.board.get(r, c), 0, reason: 'picks an empty cell');
      expect(cubit.state.isGiven(r, c), false);
      cubit.close();
    });

    test('second tap after the auto-select actually spends the hint', () {
      final cubit = GameCubit.newGame(repos: repos, difficulty: Difficulty.easy, seed: 42);

      expect(cubit.useHint(), false);
      final r = cubit.state.selectedRow!;
      final c = cubit.state.selectedCol!;

      expect(cubit.useHint(), true);
      expect(cubit.state.board.get(r, c), cubit.state.solution.get(r, c));
      expect(cubit.state.hintsRemaining, 2);
      cubit.close();
    });

    test('useHint on a given cell re-selects instead of no-oping', () {
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

      expect(cubit.useHint(), false);
      expect(cubit.state.hintsRemaining, 3);
      expect(cubit.state.isGiven(cubit.state.selectedRow!, cubit.state.selectedCol!),
          false,
          reason: 'moved off the given cell to a usable one');
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
    test('useHint reveals correct value', () {
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
      cubit.useHint();

      expect(cubit.state.board.get(emptyRow, emptyCol), correctValue);
      expect(cubit.state.hintsRemaining, 2);
      cubit.close();
    });

    test('useHint with 0 remaining is no-op', () {
      final cubit = GameCubit.newGame(repos: repos, seed: 42);

      // Find 3 empty cells and use hints
      int hintsUsed = 0;
      for (int r = 0; r < 9 && hintsUsed < 3; r++) {
        for (int c = 0; c < 9 && hintsUsed < 3; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            cubit.selectCell(r, c);
            cubit.useHint();
            hintsUsed++;
          }
        }
      }
      expect(cubit.state.hintsRemaining, 0);

      // Find another empty cell
      for (int r = 0; r < 9; r++) {
        for (int c = 0; c < 9; c++) {
          if (cubit.state.board.get(r, c) == 0) {
            cubit.selectCell(r, c);
            cubit.useHint();
            expect(cubit.state.hintsRemaining, 0); // unchanged
            cubit.close();
            return;
          }
        }
      }
      cubit.close();
    });

    test('undo hint restores hint count', () {
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

      cubit.selectCell(emptyRow!, emptyCol!);
      cubit.useHint();
      expect(cubit.state.hintsRemaining, 2);

      cubit.undo();
      expect(cubit.state.hintsRemaining, 3);
      expect(cubit.state.board.get(emptyRow, emptyCol), 0);
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

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/storage_service.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_state.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    StorageService.init(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('GameCubit.newGame', () {
    test('creates a valid game state', () {
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);
      expect(cubit.state.status, GameStatus.playing);
      expect(cubit.state.difficulty, Difficulty.easy);
      expect(cubit.state.hintsRemaining, 3);
      expect(cubit.state.mistakeCount, 0);
      expect(cubit.state.isDaily, false);
      expect(cubit.state.givenCells.isNotEmpty, true);
      cubit.close();
    });

    test('seeded generation is deterministic', () {
      final cubit1 = GameCubit.newGame(difficulty: Difficulty.medium, seed: 123);
      final cubit2 = GameCubit.newGame(difficulty: Difficulty.medium, seed: 123);
      expect(cubit1.state.puzzle, cubit2.state.puzzle);
      expect(cubit1.state.solution, cubit2.state.solution);
      cubit1.close();
      cubit2.close();
    });
  });

  group('GameCubit.daily', () {
    test('creates a daily game', () {
      final cubit = GameCubit.daily(date: DateTime(2025, 3, 10)); // Monday = easy
      expect(cubit.state.isDaily, true);
      expect(cubit.state.difficulty, Difficulty.easy);
      cubit.close();
    });
  });

  group('Cell selection', () {
    test('selectCell updates state', () {
      final cubit = GameCubit.newGame(seed: 1);
      cubit.selectCell(0, 0);
      expect(cubit.state.selectedRow, 0);
      expect(cubit.state.selectedCol, 0);
      expect(cubit.state.hasSelection, true);
      cubit.close();
    });
  });

  group('Place number', () {
    test('placing correct number updates board', () {
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);

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
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);

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
      final cubit = GameCubit.newGame(seed: 1);
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
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);

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
      final cubit = GameCubit.newGame(seed: 1);
      cubit.undo(); // should not throw
      expect(cubit.state.history, isEmpty);
      cubit.close();
    });
  });

  group('Hints', () {
    test('useHint reveals correct value', () {
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);

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
      final cubit = GameCubit.newGame(seed: 42);

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
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);

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
      final cubit = GameCubit.newGame(seed: 1);
      expect(cubit.state.isNotesMode, false);
      cubit.toggleNotesMode();
      expect(cubit.state.isNotesMode, true);
      cubit.toggleNotesMode();
      expect(cubit.state.isNotesMode, false);
      cubit.close();
    });

    test('place note in notes mode', () {
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);
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
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);

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
      final cubit = GameCubit.newGame(difficulty: Difficulty.easy, seed: 42);
      expect(cubit.techniques, isNotEmpty);
      cubit.close();
    });
  });
}

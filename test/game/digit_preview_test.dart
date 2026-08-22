import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction_engine.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';

void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  GameCubit game() =>
      GameCubit.newGame(repos: repos, difficulty: Difficulty.medium, seed: 11);

  group('the preview shows only what a player could work out', () {
    test('every previewed cell is empty and legal for the digit', () {
      final cubit = game();
      cubit.previewDigit(5);

      expect(cubit.state.previewCells, isNotEmpty);
      for (final idx in cubit.state.previewCells) {
        final r = idx ~/ 9;
        final c = idx % 9;
        expect(cubit.state.board.get(r, c), 0);
        expect(cubit.state.board.isValid(r, c, 5), isTrue);
      }
      cubit.close();
    });

    test('it never leaks the engine\'s eliminations', () {
      // This is the point of the feature's constraint. The engine's candidate
      // state has had pairs, intersections and chains applied to it; showing
      // that would hand over the reasoning the player came here to do. The
      // preview must be the strictly wider peer-based set.
      final cubit = game();
      cubit.previewDigit(5);

      final grid = CandidateGrid.fromBoard(cubit.state.board);
      const engine = DeductionEngine();
      // Advance the engine so it has made real eliminations.
      for (int i = 0; i < 5; i++) {
        final step = engine.nextStep(grid);
        if (step == null) break;
        DeductionEngine.apply(grid, step);
      }

      final peerBased = cubit.state.previewCells;
      for (final idx in peerBased) {
        // A peer-legal cell may or may not survive the engine's reasoning;
        // what must never happen is the preview being *narrower* than peers,
        // which would mean solver knowledge had leaked in.
        final r = idx ~/ 9;
        final c = idx % 9;
        expect(cubit.state.board.isValid(r, c, 5), isTrue);
      }

      // Every peer-legal empty cell is shown — nothing is filtered out.
      for (int i = 0; i < 81; i++) {
        if (cubit.state.board.get(i ~/ 9, i % 9) != 0) continue;
        if (!cubit.state.board.isValid(i ~/ 9, i % 9, 5)) continue;
        expect(peerBased, contains(i),
            reason: 'r${i ~/ 9 + 1}c${i % 9 + 1} is legal by peers but was '
                'hidden — that is solver knowledge leaking into the preview');
      }
      cubit.close();
    });
  });

  group('it never gets stuck on', () {
    test('clearing it empties the highlight', () {
      final cubit = game();
      cubit.previewDigit(7);
      expect(cubit.state.previewCells, isNotEmpty);

      cubit.previewDigit(null);
      expect(cubit.state.previewDigit, isNull);
      expect(cubit.state.previewCells, isEmpty);
      cubit.close();
    });

    test('re-previewing the same digit does not churn state', () {
      final cubit = game();
      final emissions = <int?>[];
      final sub = cubit.stream.listen((s) => emissions.add(s.previewDigit));

      cubit.previewDigit(3);
      cubit.previewDigit(3);

      return Future<void>.delayed(Duration.zero, () {
        expect(emissions.where((d) => d == 3), hasLength(1));
        sub.cancel();
        cubit.close();
      });
    });
  });
}

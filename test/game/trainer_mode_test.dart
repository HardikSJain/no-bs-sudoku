import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/deduction/candidate_grid.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/deduction/trainer_drill.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';
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

  tearDown(() async => db.close());

  Future<GameCubit> drill(Technique t) async {
    final cubit =
        await GameCubit.trainerAsync(repos: repos, technique: t);
    expect(cubit, isNotNull, reason: 'could not build a ${t.name} drill');
    return cubit!;
  }

  group('a drill is one move', () {
    test('placing the target digit finishes it', () async {
      final cubit = await drill(Technique.hiddenSingle);
      expect(cubit.state.isDrill, isTrue);
      expect(cubit.state.status, GameStatus.playing);

      final (idx, digit) = cubit.state.activeDrillStep!.targets.first;
      cubit.selectCell(idx ~/ 9, idx % 9);
      cubit.placeNumber(digit);

      expect(cubit.state.status, GameStatus.complete);
      await cubit.close();
    });

    test('an elimination drill finishes when the candidates go', () async {
      final cubit = await drill(Technique.nakedPair);
      final step = cubit.state.activeDrillStep!;
      expect(step.kind, DeductionKind.elimination);

      cubit.toggleNotesMode();
      for (final (idx, digit) in step.targets) {
        cubit.selectCell(idx ~/ 9, idx % 9);
        cubit.placeNumber(digit); // in notes mode this toggles the candidate
      }

      expect(cubit.state.status, GameStatus.complete);
      await cubit.close();
    });
  });

  group('a drill never prints its own answer', () {
    // Reported from a device: "when i open the first technique the hints were
    // already there, the answers were in front of me." The first technique is
    // the naked single, and the drill used to arrive with every candidate
    // pencilled in — which for that one technique leaves cells showing a
    // single pencil mark. That mark is the answer.
    // One pass over every drillable technique. Generation is the expensive
    // part, so both rules are checked against the same drill rather than
    // paying for a second one.
    test('what a drill hands over, technique by technique', () {
      for (final t in Technique.values.where((t) => t.isDrillable)) {
        final g = SudokuGenerator().generateTargeting(t, attempts: 1200);
        if (g == null) continue; // generation is budgeted; a miss is not news
        final drill = const TrainerDrillBuilder().build(t, g.puzzle, g.solution);
        if (drill == null) continue;

        // Nothing arrives already solved. A cell showing one pencil mark is
        // the answer written into the cell it answers.
        final giveaways =
            drill.notes.values.where((c) => c.length == 1).length;
        expect(giveaways, 0,
            reason: 'a ${t.name} drill hands over $giveaways solved cells');

        // Did the fast-forward eliminate anything, or only place digits?
        final plain = CandidateGrid.fromBoard(drill.board);
        final narrowed = plain.unsolvedCells.any((idx) {
          final seeded = drill.notes[idx];
          if (seeded == null) return false;
          return plain.candidatesOf(idx).any((d) => !seeded.contains(d));
        });

        // An elimination drill is always seeded — the move is crossing a
        // candidate out, and you cannot cross out a mark that was never
        // drawn. A placement drill is seeded only if the scaffolding hid
        // something from the board, which for the singles it never does.
        if (drill.step.kind == DeductionKind.elimination) {
          expect(drill.isScaffolded, isTrue,
              reason: '${t.name} asks for an elimination with nothing to '
                  'eliminate from');
        } else if (narrowed) {
          expect(drill.isScaffolded, isTrue,
              reason: '${t.name} hides part of the position');
        } else {
          expect(drill.notes, isEmpty,
              reason: '${t.name} seeded notes that only restate the board');
          expect(drill.isScaffolded, isFalse);
        }
      }
    }, timeout: const Timeout(Duration(minutes: 5)));

    test('the singles arrive with nothing pencilled in', () async {
      for (final t in [Technique.nakedSingle, Technique.hiddenSingle]) {
        final cubit = await drill(t);
        expect(cubit.state.notes, isEmpty,
            reason: 'a ${t.name} drill is a scanning exercise; pencilling it '
                'in for the player does the scan for them');
        expect(cubit.state.drillScaffolded, isFalse);
        await cubit.close();
      }
    });

    test('an unscaffolded drill is still finishable and still hintable',
        () async {
      final cubit = await drill(Technique.nakedSingle);
      expect(cubit.state.drillScaffolded, isFalse);
      expect(cubit.state.notes, isEmpty);

      // The hint must read the board, not an empty note map — passing {} as
      // authoritative scaffolding would describe a grid with no candidates
      // anywhere and explain a position nobody is looking at.
      final hint = cubit.useHint();
      expect(hint, isA<HintStep>());
      expect((hint as HintStep).deduction.technique, Technique.nakedSingle);

      final (idx, digit) = cubit.state.activeDrillStep!.targets.first;
      cubit.selectCell(idx ~/ 9, idx % 9);
      cubit.placeNumber(digit);
      expect(cubit.state.status, GameStatus.complete);
      await cubit.close();
    });
  });

  group('the scaffolding belongs to the puzzle', () {
    test('every pre-filled cell is a clue, not something to erase', () async {
      final cubit = await drill(Technique.xyWing);
      for (int i = 0; i < 81; i++) {
        if (cubit.state.board.get(i ~/ 9, i % 9) == 0) continue;
        expect(cubit.state.isGiven(i ~/ 9, i % 9), isTrue,
            reason: 'r${i ~/ 9 + 1}c${i % 9 + 1} was fast-forwarded in, so '
                'the player must not be able to erase or be scored on it');
      }
      await cubit.close();
    });

    test('the notes arrive seeded', () async {
      final cubit = await drill(Technique.simpleColoring);
      // Without them the eliminations that set the pattern up are invisible.
      expect(cubit.state.notes, isNotEmpty);
      await cubit.close();
    });
  });

  group('a drill is never graded', () {
    test('finishing one writes no record and moves no streak', () async {
      final cubit = await drill(Technique.hiddenSingle);
      final before = await repos.records.getRecordCount();
      final profileBefore = await repos.profiles.getProfile();

      final (idx, digit) = cubit.state.activeDrillStep!.targets.first;
      cubit.selectCell(idx ~/ 9, idx % 9);
      cubit.placeNumber(digit);
      await cubit.saveComplete;

      expect(await repos.records.getRecordCount(), before,
          reason: 'a scaffolded one-move drill in the records would drag '
              'every average down and hand out seconds-long personal bests');
      final after = await repos.profiles.getProfile();
      expect(after.currentStreak, profileBefore.currentStreak);
      expect(after.totalSolved, profileBefore.totalSolved);
      await cubit.close();
    });
  });

  group('hints inside a drill read the right position', () {
    test('the hint is the drill', () async {
      final cubit = await drill(Technique.xyWing);
      final result = cubit.useHint();

      // The hint engine must build its grid from board *and* notes here. From
      // the board alone the eliminations that set up the chain are gone and
      // it would explain a different, easier step.
      expect(result, isA<HintStep>());
      expect((result as HintStep).deduction, cubit.state.activeDrillStep);
      await cubit.close();
    });
  });
}

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';

/// A save that cannot be reopened.
///
/// The recovery used to be silent and wrong: delete the row and return
/// `newGame()`, which defaults to medium. So pressing continue on an easy
/// game destroyed it and opened a different, empty, medium puzzle, with
/// nothing said about either. Found by seeding a broken row by hand and
/// pressing continue — the app cheerfully started someone else's puzzle.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  SavedGame row({
    String given = '',
    String solution = '',
    String board = '',
    String notes = '{}',
  }) =>
      SavedGame(
        id: 1,
        puzzleId: 'p',
        difficulty: 'easy',
        isDaily: false,
        givenCells: given,
        solutionCells: solution,
        boardCells: board,
        notes: notes,
        elapsedSeconds: 10,
        hintsRemaining: 0,
        mistakeCount: 0,
        isNotesMode: false,
        savedAt: DateTime.now(),
        history: '',
        placementDeltas: '',
        mistakeCells: '',
        undoCount: 0,
        usedNotes: false,
        longestPauseSeconds: 0,
        techniques: '',
        hintsUsed: 0,
        hintDepthTotal: 0,
      );

  String get81(int v) => List.filled(81, v).join(',');

  test('a good save is restorable', () {
    expect(
      GameCubit.canRestore(row(
        given: get81(0),
        solution: get81(1),
        board: get81(0),
      )),
      isTrue,
    );
  });

  group('a save missing what a board is made of is refused', () {
    test('empty cell strings', () {
      expect(GameCubit.canRestore(row()), isFalse,
          reason: 'this is the exact row that opened a medium puzzle');
    });

    test('non-numeric cells', () {
      expect(
        GameCubit.canRestore(row(
          given: List.filled(81, 'x').join(','),
          solution: get81(1),
          board: get81(0),
        )),
        isFalse,
      );
    });

    test('notes that are not a map', () {
      expect(
        GameCubit.canRestore(row(
          given: get81(0),
          solution: get81(1),
          board: get81(0),
          notes: 'not json',
        )),
        isFalse,
      );
    });
  });

  test('the last-resort net still does not keep an unusable row', () async {
    // `fromSaved` remains the net behind the route guard. What it must not do
    // is leave the dead row in place for the resume bar to keep offering.
    await repos.savedGames.saveGame(SavedGamesCompanion.insert(
      puzzleId: 'broken',
      difficulty: 'easy',
      isDaily: false,
      givenCells: '',
      solutionCells: '',
      boardCells: '',
      notes: '{}',
      elapsedSeconds: 5,
      hintsRemaining: 0,
      mistakeCount: 0,
      isNotesMode: false,
      savedAt: DateTime.now(),
      history: const Value(''),
    ));

    final cubit = GameCubit.fromSaved(
      (await repos.savedGames.getSavedGames()).other!,
      repos,
    );
    await Future<void>.delayed(Duration.zero);

    expect((await repos.savedGames.getSavedGames()).other, isNull,
        reason: 'a row that cannot be opened must not stay on the shelf');
    await cubit.close();
  });
}

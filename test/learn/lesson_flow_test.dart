import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/app.dart';
import 'package:no_bs_sudoku/core/routing/app_router.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/widgets/sudoku_grid.dart';

/// The library → technique → drill → back journey, end to end.
///
/// Every assertion here corresponds to something that was reported as broken
/// from a real device: finishing a drill threw you out to the top of the
/// library, the hardware back button then closed the app, and the practice
/// you had just done did not show up.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
    resetAppRouter();
  });

  tearDown(() async => db.close());

  List<String> stack() => appRouter
      .routerDelegate.currentConfiguration.matches
      .map((m) => m.matchedLocation)
      .toList();

  /// Boots the app on home and walks to a drill the way a player does.
  Future<GameCubit> walkToDrill(WidgetTester tester, Technique technique) async {
    tester.view.physicalSize = const Size(402 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await repos.preferences.markOnboardingSeen();
    await tester.pumpWidget(App(repositories: repos));
    await tester.pumpAndSettle(const Duration(seconds: 3));

    appRouter.push('/learn');
    await tester.pumpAndSettle();
    // Nothing has been practised yet, so no row carries a level chip that
    // only a drill can produce. This is the baseline the tests below move.
    expect(find.text('learning'), findsNothing);

    appRouter.push('/learn/${technique.name}');
    await tester.pumpAndSettle();
    appRouter.push('/train/${technique.name}');
    await tester.pumpAndSettle();
    // Drills are generated on a real isolate, which a fake-async pump will
    // never let finish.
    await tester.runAsync(() => Future<void>.delayed(const Duration(seconds: 8)));
    await tester.pumpAndSettle();

    expect(find.byType(SudokuGrid), findsOneWidget,
        reason: 'the drill never finished generating');
    return BlocProvider.of<GameCubit>(tester.element(find.byType(SudokuGrid)));
  }

  Future<void> solveDrill(WidgetTester tester, GameCubit cubit) async {
    final step = cubit.state.activeDrillStep!;
    if (step.kind == DeductionKind.placement) {
      for (final (idx, digit) in step.targets) {
        cubit.selectCell(idx ~/ 9, idx % 9);
        cubit.placeNumber(digit);
      }
    } else {
      cubit.toggleNotesMode();
      for (final (idx, digit) in step.targets) {
        cubit.selectCell(idx ~/ 9, idx % 9);
        cubit.placeNumber(digit);
      }
    }
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  testWidgets('finishing a drill returns to the technique you came from',
      (tester) async {
    final cubit = await walkToDrill(tester, Technique.hiddenSingle);
    expect(stack(), [
      '/home',
      '/learn',
      '/learn/hiddenSingle',
      '/train/hiddenSingle',
    ]);

    await solveDrill(tester, cubit);

    // Not the top of the library. The page you were reading, with the record
    // card that just changed on it.
    expect(stack(), ['/home', '/learn', '/learn/hiddenSingle'],
        reason: 'a finished drill must return to its technique, and must not '
            'throw away the stack that got you there');
  });

  testWidgets('the back button still works after a drill', (tester) async {
    final cubit = await walkToDrill(tester, Technique.hiddenSingle);
    await solveDrill(tester, cubit);

    // The reported symptom: back closed the app instead of going back.
    expect(appRouter.routerDelegate.canPop(), isTrue,
        reason: 'back would close the app');

    appRouter.pop();
    await tester.pumpAndSettle();
    expect(stack(), ['/home', '/learn']);

    appRouter.pop();
    await tester.pumpAndSettle();
    expect(stack(), ['/home']);
  });

  testWidgets('the drill you just did shows up on the technique page',
      (tester) async {
    final cubit = await walkToDrill(tester, Technique.hiddenSingle);
    await solveDrill(tester, cubit);

    // It reached the database — that was never the broken part.
    final profile = await repos.mastery.getProfile();
    expect(profile[Technique.hiddenSingle].drillsAttempted, 1);

    // The part that was broken: the screen never re-read it.
    expect(find.text('try a drill.'), findsNothing,
        reason: 'the technique page is still showing pre-drill state');
    expect(find.text('1'), findsWidgets,
        reason: 'the record card should show the drill that was just done');
  });

  testWidgets('a drill you walk away from is not left lying around',
      (tester) async {
    // It used to be saved. The save row cannot carry the technique or the
    // target move, so it came back as an ordinary medium puzzle that could
    // never be finished as a drill — and finishing it as a puzzle wrote a
    // record and moved the streak, off a grid the engine had already
    // four-fifths solved.
    final cubit = await walkToDrill(tester, Technique.hiddenSingle);
    final step = cubit.state.activeDrillStep!;
    final spare = List.generate(81, (i) => i).firstWhere((i) =>
        !step.targets.map((t) => t.$1).contains(i) &&
        !cubit.state.givenCells.contains(i) &&
        cubit.state.board.get(i ~/ 9, i % 9) == 0);
    cubit.toggleNotesMode();
    cubit.selectCell(spare ~/ 9, spare % 9);
    cubit.placeNumber(1);
    await cubit.flushSave();

    final saved = await repos.savedGames.getSavedGames();
    expect(saved.other, isNull,
        reason: 'a drill must never offer itself as a resumable puzzle');
    expect(saved.daily, isNull);
  });

  testWidgets('and starting one does not evict the game you had going',
      (tester) async {
    // The worse half of the same bug. Both a drill and a casual game claimed
    // the not-daily slot, and saving replaces that slot outright — so opening
    // a drill and touching one cell threw away the puzzle you were part-way
    // through, with no warning and nothing to undo it.
    await repos.savedGames.saveGame(SavedGamesCompanion.insert(
      puzzleId: 'quick-one',
      difficulty: 'hard',
      isDaily: false,
      givenCells: '0' * 81,
      solutionCells: '1' * 81,
      boardCells: '0' * 81,
      notes: '{}',
      elapsedSeconds: 400,
      hintsRemaining: 0,
      mistakeCount: 0,
      isNotesMode: false,
      savedAt: DateTime.now(),
    ));

    final cubit = await walkToDrill(tester, Technique.hiddenSingle);
    final step = cubit.state.activeDrillStep!;
    final spare = List.generate(81, (i) => i).firstWhere((i) =>
        !step.targets.map((t) => t.$1).contains(i) &&
        !cubit.state.givenCells.contains(i) &&
        cubit.state.board.get(i ~/ 9, i % 9) == 0);
    cubit.toggleNotesMode();
    cubit.selectCell(spare ~/ 9, spare % 9);
    cubit.placeNumber(1);
    await cubit.flushSave();

    final saved = await repos.savedGames.getSavedGames();
    expect(saved.other?.puzzleId, 'quick-one',
        reason: 'the hard puzzle in progress was thrown away by a drill');
    expect(saved.other?.elapsedSeconds, 400);
  });

  testWidgets('and on the library list underneath it', (tester) async {
    final cubit = await walkToDrill(tester, Technique.hiddenSingle);
    await solveDrill(tester, cubit);

    appRouter.pop();
    await tester.pumpAndSettle();
    expect(stack(), ['/home', '/learn']);

    // One drill moves hidden single off "not met yet" and onto "learning".
    // The list was built before that happened, so this only passes if it
    // re-read on the way back.
    expect(find.text('learning'), findsOneWidget,
        reason: 'the library list is stale after a drill');
  });
}

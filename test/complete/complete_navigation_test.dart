import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/app.dart';
import 'package:no_bs_sudoku/core/routing/app_router.dart';
import 'package:no_bs_sudoku/core/routing/route_args.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';

/// Where "done" puts you after a puzzle, and what back can reach from there.
///
/// The solved screen used to replace the whole stack, so finishing a puzzle
/// picked off the ninety-day calendar dropped you on home with the calendar
/// gone. It replaces only the puzzle now.
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

  Future<void> boot(WidgetTester tester) async {
    tester.view.physicalSize = const Size(402 * 3, 2400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    await repos.preferences.markOnboardingSeen();
    await tester.pumpWidget(App(repositories: repos));
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }

  CompleteRouteArgs args() => const CompleteRouteArgs(
        qualityScore: 80,
        timeSeconds: 300,
        hintsUsed: 0,
        mistakes: 0,
        difficulty: Difficulty.hard,
        isDaily: true,
        solveTimes: [],
      );

  testWidgets('solving an archive daily leaves the calendar behind it',
      (tester) async {
    await boot(tester);
    appRouter.push('/daily');
    await tester.pumpAndSettle();
    appRouter.push('/game/daily/2026-08-03');
    await tester.pumpAndSettle();
    expect(stack(), ['/home', '/daily', '/game/daily/2026-08-03']);

    // What the game screen does on completion.
    appRouter.pushReplacement('/complete', extra: args());
    await tester.pumpAndSettle();

    expect(stack(), ['/home', '/daily', '/complete'],
        reason: 'the calendar you picked the puzzle from must survive');
  });

  testWidgets('and back cannot walk into the puzzle you just solved',
      (tester) async {
    await boot(tester);
    appRouter.push('/daily');
    await tester.pumpAndSettle();
    appRouter.push('/game/daily/2026-08-03');
    await tester.pumpAndSettle();
    appRouter.pushReplacement('/complete', extra: args());
    await tester.pumpAndSettle();

    appRouter.pop();
    await tester.pumpAndSettle();
    expect(stack(), ['/home', '/daily'],
        reason: 'done goes back to the calendar, not into the solved grid');
  });

  testWidgets('a quick game from home still ends up on home', (tester) async {
    await boot(tester);
    appRouter.push('/game/medium');
    await tester.pumpAndSettle();
    appRouter.pushReplacement('/complete', extra: args());
    await tester.pumpAndSettle();
    expect(stack(), ['/home', '/complete']);

    appRouter.pop();
    await tester.pumpAndSettle();
    expect(stack(), ['/home']);
    expect(appRouter.routerDelegate.canPop(), isFalse,
        reason: 'home is the bottom; back from here leaves the app');
  });

  testWidgets('a deep link straight to a puzzle still has somewhere to go',
      (tester) async {
    await boot(tester);
    // No stack under it, which is the one case that needs the fallback.
    appRouter.go('/complete', extra: args());
    await tester.pumpAndSettle();
    expect(stack(), ['/complete']);
    expect(appRouter.routerDelegate.canPop(), isFalse);
  });
}

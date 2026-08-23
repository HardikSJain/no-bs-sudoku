import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/routing/route_args.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/engine/deduction/deduction.dart';
import 'package:no_bs_sudoku/engine/sudoku_board.dart';
import 'package:no_bs_sudoku/engine/sudoku_solver.dart';
import 'package:no_bs_sudoku/features/complete/complete_screen.dart';
import 'package:no_bs_sudoku/features/daily/daily_archive_screen.dart';
import 'package:no_bs_sudoku/features/game/game_cubit.dart';
import 'package:no_bs_sudoku/features/game/game_screen.dart';
import 'package:no_bs_sudoku/features/home/home_screen.dart';
import 'package:no_bs_sudoku/features/import/import_screen.dart';
import 'package:no_bs_sudoku/features/learn/learn_cubit.dart';
import 'package:no_bs_sudoku/features/learn/learn_screen.dart';
import 'package:no_bs_sudoku/features/learn/technique_detail_screen.dart';
import 'package:no_bs_sudoku/features/learn/tier_detail_screen.dart';
import 'package:no_bs_sudoku/features/onboarding/onboarding_screen.dart';
import 'package:no_bs_sudoku/features/settings/settings_screen.dart';
import 'package:no_bs_sudoku/features/stats/stats_screen.dart';

/// Every screen, rendered narrow, checked for anything running off its edge.
///
/// This exists because the difficulty card had been overflowing by 32 points
/// for months and nobody knew: the home screen had never been rendered whole
/// in a test, only its pieces. A layout bug found here costs a minute; found
/// by a player it costs a one-star review that says "text is cut off".
///
/// About the width. The test font is a monospace square — every glyph is as
/// wide as it is tall — where Space Mono advances about 0.6em. So laying out
/// at 320 points here is roughly what 320 points looks like at 1.6x the
/// system text size on a real phone, which is squarely inside the 2x this
/// app allows. That is the bar: not "does it fit at default", but "does it
/// still fit when somebody has turned the text up".
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  /// Tall on purpose: a screen that scrolls should be checked whole, and a
  /// sliver below the fold is never built otherwise.
  Future<void> pump(WidgetTester tester, Widget screen,
      {double width = 320, double height = 2600}) async {
    tester.view.physicalSize = Size(width * 3, height * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    // Captured rather than left to the framework, so a failure names the
    // widget instead of only its size.
    final errors = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = errors.add;

    await tester.pumpWidget(MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repos.records),
        RepositoryProvider.value(value: repos.profiles),
        RepositoryProvider.value(value: repos.preferences),
        RepositoryProvider.value(value: repos.savedGames),
        RepositoryProvider.value(value: repos.mastery),
        RepositoryProvider.value(value: repos),
      ],
      child: MaterialApp(
        theme: appTheme(),
        // A router, because several screens push and pop.
        home: screen,
      ),
    ));
    await tester.pumpAndSettle();
    FlutterError.onError = previous;

    expect(
      errors,
      isEmpty,
      reason: errors.map((e) => e.toString()).join('\n\n'),
    );
  }

  Future<void> seedSolve() => repos.records.saveRecord(PuzzleRecordsCompanion(
        puzzleId: const Value('t1'),
        difficulty: const Value('expert'),
        timeSeconds: const Value(3725),
        completedAt: Value(DateTime.now()),
        qualityScore: const Value(72),
      ));

  testWidgets('home', (tester) async {
    await pump(tester, const HomeScreen());
  });

  testWidgets('home, with a solve behind it', (tester) async {
    await seedSolve();
    await pump(tester, const HomeScreen());
  });

  testWidgets('stats', (tester) async {
    await seedSolve();
    await pump(tester, const StatsScreen());
  });

  testWidgets('stats, empty', (tester) async {
    await pump(tester, const StatsScreen());
  });

  testWidgets('settings', (tester) async {
    await pump(tester, const SettingsScreen());
  });

  testWidgets('the daily archive', (tester) async {
    await pump(tester, const DailyArchiveScreen(), height: 6000);
  });

  testWidgets('import', (tester) async {
    await pump(tester, const ImportScreen());
  });

  testWidgets('onboarding', (tester) async {
    await pump(tester, const OnboardingScreen());
  });

  testWidgets('the technique library', (tester) async {
    await pump(
      tester,
      BlocProvider(
        create: (_) => LearnCubit(repos.mastery),
        child: const LearnScreen(),
      ),
      height: 4000,
    );
  });

  for (final tier in TechniqueTier.values) {
    testWidgets('the ${tier.name} tier page', (tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => LearnCubit(repos.mastery),
          child: TierDetailScreen(tier: tier),
        ),
        height: 4000,
      );
    });
  }

  for (final technique in Technique.values) {
    testWidgets('the ${technique.name} page', (tester) async {
      await pump(
        tester,
        BlocProvider(
          create: (_) => LearnCubit(repos.mastery),
          child: TechniqueDetailScreen(technique: technique),
        ),
        height: 4000,
      );
    });
  }

  testWidgets('the complete screen', (tester) async {
    await pump(
      tester,
      MaterialApp(
        theme: appTheme(),
        home: CompleteScreen(
          args: CompleteRouteArgs(
            qualityScore: 87.4,
            timeSeconds: 3725,
            hintsUsed: 2,
            mistakes: 1,
            difficulty: Difficulty.expert,
            isDaily: true,
            solveTimes: const [10, 20, 30],
            techniques: const {Technique.xWing, Technique.simpleColoring},
            puzzle: SudokuBoard.empty(),
            history: const [],
          ),
        ),
      ),
      height: 3000,
    );
  });

  group('the game screen', () {
    // Not through `pump`: GameCubit runs a periodic timer, so pumpAndSettle
    // never returns, and its close() has to happen inside the test body. See
    // the note on GameCubit.close.
    Future<void> pumpBoard(WidgetTester tester, SavedGame saved,
        {double width = 320, double height = 700}) async {
      tester.view.physicalSize = Size(width * 3, height * 3);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.reset);

      final errors = <FlutterErrorDetails>[];
      final previous = FlutterError.onError;
      FlutterError.onError = errors.add;

      await tester.pumpWidget(MultiRepositoryProvider(
        providers: [
          RepositoryProvider.value(value: repos.records),
          RepositoryProvider.value(value: repos.profiles),
          RepositoryProvider.value(value: repos.preferences),
          RepositoryProvider.value(value: repos.savedGames),
          RepositoryProvider.value(value: repos.mastery),
          RepositoryProvider.value(value: repos),
        ],
        child: MaterialApp(
          theme: appTheme(),
          home: GameScreen(difficulty: Difficulty.easy, resumeFrom: saved),
        ),
      ));
      for (var i = 0; i < 4; i++) {
        await tester.pump(const Duration(milliseconds: 300));
      }
      FlutterError.onError = previous;

      expect(errors, isEmpty,
          reason: errors.map((e) => e.toString()).join('\n\n'));
    }

    /// A real save, so the board, the notes and the pad counts are real.
    Future<SavedGame> aSavedGame({bool withHint = false}) async {
      final cubit = GameCubit.newGame(
          repos: repos, difficulty: Difficulty.easy, seed: 42)
        ..pauseTimer();
      if (withHint) {
        cubit.useHint();
        cubit.useHint();
        cubit.useHint();
      }
      cubit.autoFillNotes();
      await cubit.flushSave();
      await cubit.close();
      return (await repos.savedGames.getMostRecent())!;
    }

    testWidgets('a board full of pencil marks, on the smallest phone',
        (tester) async {
      await pumpBoard(tester, await aSavedGame(), height: 548);
    });

    testWidgets('and on a tall one', (tester) async {
      await pumpBoard(tester, await aSavedGame(), height: 900);
    });

    testWidgets('with the hint panel open at its longest', (tester) async {
      // The explain rung carries the name, the explanation and the cue.
      await pumpBoard(tester, await aSavedGame(withHint: true), height: 548);
    });
  });
}

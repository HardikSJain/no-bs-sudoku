import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/core/intelligence/intelligence_engine.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import 'package:no_bs_sudoku/core/theme/app_theme.dart';
import 'package:no_bs_sudoku/features/home/home_cubit.dart';
import 'package:no_bs_sudoku/features/home/home_screen.dart';

/// What the home screen decides is still worth resuming.
void main() {
  late AppDatabase db;
  late Repositories repos;
  HomeCubit? cubit;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  Future<void> save({
    required String puzzleId,
    required bool isDaily,
    int elapsed = 120,
  }) =>
      repos.savedGames.saveGame(SavedGamesCompanion.insert(
        puzzleId: puzzleId,
        difficulty: 'hard',
        isDaily: isDaily,
        givenCells: List.filled(81, 0).join(','),
        solutionCells: List.filled(81, 1).join(','),
        boardCells: List.filled(81, 0).join(','),
        notes: '',
        elapsedSeconds: elapsed,
        hintsRemaining: 0,
        mistakeCount: 0,
        isNotesMode: false,
        savedAt: DateTime.now(),
      ));

  Future<HomeState> loaded() async {
    final c = HomeCubit(
      records: repos.records,
      profiles: repos.profiles,
      savedGames: repos.savedGames,
      intelligence: IntelligenceEngine(repos.records, repos.profiles),
    );
    cubit = c;
    addTearDown(() async => c.close());
    return c.stream.firstWhere((s) => s.loaded);
  }

  test('today\'s daily and a quick game both survive', () async {
    await save(puzzleId: dailyPuzzleId(), isDaily: true);
    await save(puzzleId: 'quick', isDaily: false);

    final state = await loaded();
    expect(state.saved.daily, isNotNull);
    expect(state.saved.other, isNotNull);
  });

  test('a half-finished archive daily is kept, not swept', () async {
    // It used to be deleted the moment it was not today's, which quietly ate
    // any archive puzzle left part-way through.
    final tuesday = todayUtc().subtract(const Duration(days: 5));
    await save(puzzleId: dailyPuzzleId(tuesday), isDaily: true);

    final state = await loaded();
    expect(state.saved.daily?.puzzleId, dailyPuzzleId(tuesday));
  });

  test('but one older than the archive goes', () async {
    final ancient =
        todayUtc().subtract(Duration(days: dailyArchiveDays + 5));
    await save(puzzleId: dailyPuzzleId(ancient), isDaily: true);

    final state = await loaded();
    expect(state.saved.daily, isNull);
    expect((await repos.savedGames.getSavedGames()).daily, isNull,
        reason: 'the row must be cleared, not merely hidden');
  });

  test('a puzzle glanced at for ten seconds is not a resume bar', () async {
    await save(puzzleId: 'quick', isDaily: false, elapsed: 10);

    final state = await loaded();
    expect(state.saved.other, isNull);
  });

  test('dismissing one slot leaves the other', () async {
    await save(puzzleId: dailyPuzzleId(), isDaily: true);
    await save(puzzleId: 'quick', isDaily: false);
    await loaded();

    await cubit!.dismissSavedGame(isDaily: false);

    expect(cubit!.state.saved.other, isNull);
    expect(cubit!.state.saved.daily, isNotNull);
  });

  testWidgets('the bars say which game is which', (tester) async {
    // Two bars reading "medium" and "easy" give no clue that one of them is
    // a daily from last Thursday.
    final thursday = todayUtc().subtract(const Duration(days: 3));
    await save(puzzleId: dailyPuzzleId(thursday), isDaily: true);
    await save(puzzleId: 'quick', isDaily: false);

    tester.view.physicalSize = const Size(402 * 3, 1400 * 3);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repos.records),
        RepositoryProvider.value(value: repos.profiles),
        RepositoryProvider.value(value: repos.savedGames),
      ],
      child: MaterialApp(theme: appTheme(), home: const HomeScreen()),
    ));
    await tester.pumpAndSettle();

    final label = DateFormat('d MMM').format(thursday).toLowerCase();
    expect(find.textContaining('daily, $label'), findsOneWidget);
    expect(find.textContaining('hard  ·'), findsOneWidget);
    // The whole screen, not just the bars: the difficulty cards used to
    // overflow here once their "up to intersections" line grew.
    expect(tester.takeException(), isNull);
  });
}

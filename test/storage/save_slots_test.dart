import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/core/logger.dart';
import 'package:no_bs_sudoku/core/storage/app_database.dart';
import 'package:no_bs_sudoku/core/storage/repositories/repositories.dart';

/// Two slots: the daily, and everything else.
///
/// One slot meant a player half-way through the daily could not also have a
/// hard puzzle on the go, and once the archive shipped, opening last
/// Tuesday's threw away today's.
void main() {
  late AppDatabase db;
  late Repositories repos;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repos = Repositories(db);
  });

  tearDown(() async => db.close());

  SavedGamesCompanion game({
    required String puzzleId,
    required bool isDaily,
    String difficulty = 'hard',
    int elapsed = 120,
    DateTime? at,
  }) =>
      SavedGamesCompanion.insert(
        puzzleId: puzzleId,
        difficulty: difficulty,
        isDaily: isDaily,
        givenCells: List.filled(81, 0).join(','),
        solutionCells: List.filled(81, 1).join(','),
        boardCells: List.filled(81, 0).join(','),
        notes: '',
        elapsedSeconds: elapsed,
        hintsRemaining: 0,
        mistakeCount: 0,
        isNotesMode: false,
        savedAt: at ?? DateTime.now(),
      );

  test('a daily and a quick game coexist', () async {
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    await repos.savedGames
        .saveGame(game(puzzleId: 'quick-1', isDaily: false));

    final saved = await repos.savedGames.getSavedGames();
    expect(saved.daily?.puzzleId, dailyPuzzleId());
    expect(saved.other?.puzzleId, 'quick-1');
  });

  test('a second quick game replaces the first, and leaves the daily',
      () async {
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-1', isDaily: false));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-2', isDaily: false));

    final saved = await repos.savedGames.getSavedGames();
    expect(saved.other?.puzzleId, 'quick-2');
    expect(saved.daily?.puzzleId, dailyPuzzleId(),
        reason: 'starting a quick game must not touch the daily slot');
  });

  test('and a second daily replaces the first, leaving the quick game',
      () async {
    final tuesday = todayUtc().subtract(const Duration(days: 4));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-1', isDaily: false));
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(tuesday), isDaily: true));
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));

    final saved = await repos.savedGames.getSavedGames();
    expect(saved.daily?.puzzleId, dailyPuzzleId());
    expect(saved.other?.puzzleId, 'quick-1');
  });

  test('deleting one slot leaves the other alone', () async {
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-1', isDaily: false));

    await repos.savedGames.deleteSavedGame(isDaily: true);

    final saved = await repos.savedGames.getSavedGames();
    expect(saved.daily, isNull);
    expect(saved.other?.puzzleId, 'quick-1');
  });

  test('deleteAll takes both', () async {
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-1', isDaily: false));

    await repos.savedGames.deleteAll();

    expect((await repos.savedGames.getSavedGames()).isEmpty, isTrue);
  });

  test('slotFor names the one a new game would overwrite', () async {
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    final saved = await repos.savedGames.getSavedGames();

    expect(saved.slotFor(isDaily: true)?.puzzleId, dailyPuzzleId());
    expect(saved.slotFor(isDaily: false), isNull,
        reason: 'nothing to warn about before starting a quick game');
  });

  test('the most recent is whichever was touched last', () async {
    final early = DateTime.now().subtract(const Duration(hours: 2));
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true, at: early));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-1', isDaily: false));

    expect((await repos.savedGames.getMostRecent())?.puzzleId, 'quick-1');
  });

  test('the stream reports both slots on every change', () async {
    final seen = <InProgress>[];
    final sub = repos.savedGames.savedGamesStream.listen(seen.add);
    addTearDown(sub.cancel);

    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    await repos.savedGames.saveGame(game(puzzleId: 'quick-1', isDaily: false));
    await Future<void>.delayed(Duration.zero);

    expect(seen.length, 2);
    expect(seen.first.daily, isNotNull);
    expect(seen.first.other, isNull);
    expect(seen.last.daily, isNotNull);
    expect(seen.last.other, isNotNull);
  });

  test('both slots full is reported once, not on every autosave', () async {
    // The autosave fires constantly. An event per save would drown the
    // question this one exists to answer.
    final events = <String>[];
    Log.testSink = events.add;
    addTearDown(() => Log.testSink = null);

    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    expect(events, isNot(contains('two_games_in_progress')));

    await repos.savedGames.saveGame(game(puzzleId: 'quick', isDaily: false));
    await repos.savedGames.saveGame(game(puzzleId: 'quick', isDaily: false));
    await repos.savedGames.saveGame(game(puzzleId: 'quick', isDaily: false));

    expect(events.where((e) => e == 'two_games_in_progress').length, 1);
  });

  test('and again after one slot empties and refills', () async {
    final events = <String>[];
    Log.testSink = events.add;
    addTearDown(() => Log.testSink = null);

    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    await repos.savedGames.saveGame(game(puzzleId: 'quick', isDaily: false));
    await repos.savedGames.deleteSavedGame(isDaily: false);
    await repos.savedGames.saveGame(game(puzzleId: 'quick-2', isDaily: false));

    expect(events.where((e) => e == 'two_games_in_progress').length, 2);
  });

  test('a drill left behind by an older build is dropped, not offered',
      () async {
    // Drills are no longer written, but a build that wrote one must not leave
    // it advertising itself as a resumable medium puzzle for ever.
    await repos.savedGames
        .saveGame(game(puzzleId: 'drill_hiddenSingle_1787', isDaily: false));
    expect((await repos.savedGames.getSavedGames()).other, isNull);
    expect(await repos.savedGames.getMostRecent(), isNull);

    // And it is gone from the table, not merely filtered on the way out.
    await Future<void>.delayed(Duration.zero);
    expect((await repos.savedGames.getSavedGames()).isEmpty, isTrue);
  });

  test('a real game alongside a stale drill survives', () async {
    await repos.savedGames
        .saveGame(game(puzzleId: dailyPuzzleId(), isDaily: true));
    // Written straight to the table, the way an older build would have.
    await repos.savedGames
        .saveGame(game(puzzleId: 'drill_nakedPair_9', isDaily: false));

    final now = await repos.savedGames.getSavedGames();
    expect(now.daily, isNotNull, reason: 'the daily must not be collateral');
    expect(now.other, isNull);
  });
}

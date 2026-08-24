import 'dart:async';

import 'package:drift/drift.dart';

import '../../logger.dart';
import '../app_database.dart';

/// What is currently in progress: at most one daily and at most one other.
///
/// Not `SavedGames` — drift already generates that name for the table.
class InProgress {
  const InProgress({this.daily, this.other});

  /// Today's daily, or one from the archive. Only ever one — starting a
  /// second daily replaces the first.
  final SavedGame? daily;

  /// Anything else: a quick game or an imported grid. Never a drill — see
  /// [SavedGameRepository.getSavedGames].
  final SavedGame? other;

  static const InProgress none = InProgress();

  bool get isEmpty => daily == null && other == null;

  /// The one that would be thrown away by starting a game with [isDaily].
  SavedGame? slotFor({required bool isDaily}) => isDaily ? daily : other;

  List<SavedGame> get all => [?daily, ?other];
}

/// Everything that reads or writes `saved_games`, plus the broadcast the home
/// screen's resume bar listens to.
///
/// Two slots, not one. The table used to be cleared on every save, so a
/// player half-way through the daily could not also have a hard puzzle on the
/// go — and after the archive shipped, opening last Tuesday's daily threw
/// away today's. The daily and everything else are different things to a
/// player, so they are different rows here.
class SavedGameRepository {
  SavedGameRepository(this._db);

  final AppDatabase _db;

  final _controller = StreamController<InProgress>.broadcast();

  /// Emits on every save and every delete, so the resume bar stays honest.
  Stream<InProgress> get savedGamesStream => _controller.stream;

  /// Replaces the slot this game belongs to, and leaves the other alone.
  Future<void> saveGame(SavedGamesCompanion game) async {
    final isDaily = game.isDaily.present && game.isDaily.value;
    await _db.transaction(() async {
      await (_db.delete(_db.savedGames)
            ..where((t) => t.isDaily.equals(isDaily)))
          .go();
      await _db.into(_db.savedGames).insert(game);
    });
    await _broadcast();
  }

  /// Publishes the current state, and notes when both slots first fill.
  ///
  /// One place, because the flag has to be cleared on a delete as well —
  /// otherwise finishing a game and starting another never reports again.
  Future<void> _broadcast() async {
    final now = await getSavedGames();

    // Reported the first time both slots are full at once, and not again
    // until one of them empties. The autosave fires constantly, so an event
    // per save would drown the question this one exists to answer: the two
    // slots were built on the theory that people want the daily and
    // something casual on the go together.
    final both = now.daily != null && now.other != null;
    if (both && !_bothWereFull) Log.twoGamesInProgress();
    _bothWereFull = both;

    _controller.add(now);
  }

  bool _bothWereFull = false;

  Future<InProgress> getSavedGames() async {
    final rows = await (_db.select(_db.savedGames)
          ..orderBy([(t) => OrderingTerm.desc(t.savedAt)]))
        .get();
    SavedGame? daily;
    SavedGame? other;
    final stale = <int>[];
    for (final row in rows) {
      // A drill is not resumable and is no longer written, but a build that
      // did write one must not leave it offering itself as a medium puzzle
      // forever. Dropped on sight rather than migrated: there is nothing in
      // it worth keeping.
      if (isDrillSave(row.puzzleId)) {
        stale.add(row.id);
        continue;
      }
      if (row.isDaily) {
        daily ??= row;
      } else {
        other ??= row;
      }
    }
    if (stale.isNotEmpty) {
      unawaited((_db.delete(_db.savedGames)
            ..where((t) => t.id.isIn(stale)))
          .go());
    }
    return InProgress(daily: daily, other: other);
  }

  /// Whether a stored row is a technique drill.
  ///
  /// By id, because that is the only thing on the row that says so — the
  /// column set predates drills and none of it records the technique.
  /// `GameCubit.trainerAsync` builds the id, and the two must agree.
  static bool isDrillSave(String puzzleId) => puzzleId.startsWith('drill_');

  /// The most recently saved game of either kind, or null.
  ///
  /// For the places that genuinely want "whatever I was last doing" rather
  /// than a particular slot.
  Future<SavedGame?> getMostRecent() async {
    final games = await getSavedGames();
    final all = games.all;
    if (all.isEmpty) return null;
    all.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return all.first;
  }

  /// Clears one slot.
  Future<void> deleteSavedGame({required bool isDaily}) async {
    await (_db.delete(_db.savedGames)..where((t) => t.isDaily.equals(isDaily)))
        .go();
    await _broadcast();
  }

  /// Clears both. Used by the factory reset, and by anything that means "no
  /// game is in progress" rather than "this one is finished".
  Future<void> deleteAll() async {
    await _db.delete(_db.savedGames).go();
    await _broadcast();
  }

  Future<void> dispose() => _controller.close();
}

import 'dart:async';

import '../app_database.dart';

/// Everything that reads or writes `saved_games`, plus the broadcast the home
/// screen's resume bar listens to.
class SavedGameRepository {
  SavedGameRepository(this._db);

  final AppDatabase _db;

  final _controller = StreamController<SavedGame?>.broadcast();

  /// Emits on every save and every delete, so the resume bar stays honest.
  Stream<SavedGame?> get savedGameStream => _controller.stream;

  Future<void> saveGame(SavedGamesCompanion game) async {
    await _db.transaction(() async {
      await _db.delete(_db.savedGames).go();
      await _db.into(_db.savedGames).insert(game);
    });
    _controller.add(await getSavedGame());
  }

  Future<SavedGame?> getSavedGame() {
    return (_db.select(_db.savedGames)..limit(1)).getSingleOrNull();
  }

  Future<void> deleteSavedGame() async {
    await _db.delete(_db.savedGames).go();
    _controller.add(null);
  }

  /// Used by the factory reset. Unlike the old resetAllData, which deleted the
  /// table directly and never notified, this fires the stream — otherwise the
  /// home screen keeps showing a resume bar for a game that no longer exists.
  Future<void> deleteAll() => deleteSavedGame();

  Future<void> dispose() => _controller.close();
}

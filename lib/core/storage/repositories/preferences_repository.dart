import 'package:drift/drift.dart';

import '../app_database.dart';

/// Everything that reads or writes `game_preferences_table`.
class PreferencesRepository {
  PreferencesRepository(this._db);

  final AppDatabase _db;

  Future<void> updatePreferences(GamePreferencesTableCompanion prefs) async {
    await (_db.update(_db.gamePreferencesTable)..where((t) => t.id.equals(1)))
        .write(prefs);
  }

  Future<void> markOnboardingSeen() => updatePreferences(
        const GamePreferencesTableCompanion(hasSeenOnboarding: Value(true)),
      );

  Future<GamePreferencesTableData> getPreferences() async {
    final row = await (_db.select(_db.gamePreferencesTable)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    await _db
        .into(_db.gamePreferencesTable)
        .insert(GamePreferencesTableCompanion.insert());
    return (_db.select(_db.gamePreferencesTable)..where((t) => t.id.equals(1)))
        .getSingle();
  }
}

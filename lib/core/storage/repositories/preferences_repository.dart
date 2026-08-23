import 'package:drift/drift.dart';

import '../../../features/feedback/feedback_context.dart';
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

  Future<void> setLastReviewRequestAt(DateTime at) => updatePreferences(
        GamePreferencesTableCompanion(lastReviewRequestAt: Value(at)),
      );

  /// The anonymous id attached to feedback, minted on first use.
  ///
  /// Deliberately lazy: somebody who never writes in never gets one. It is
  /// random rather than derived from anything about the device, so it
  /// identifies a stream of feedback and nothing else, and clearing the app's
  /// data throws it away.
  Future<String> installId() async {
    final existing = (await getPreferences()).installId;
    if (existing != null && existing.isNotEmpty) return existing;
    final minted = FeedbackContext.newInstallId();
    await updatePreferences(
      GamePreferencesTableCompanion(installId: Value(minted)),
    );
    return minted;
  }

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

import 'dart:async';

import '../logger.dart';
import 'app_database.dart';
import 'repositories/preferences_repository.dart';
import 'repositories/profile_repository.dart';
import 'repositories/puzzle_record_repository.dart';
import 'repositories/saved_game_repository.dart';

/// Facade over the four repositories.
///
/// This used to be a 31-method god object spanning six concerns behind a
/// global singleton, which is why every test needed a real database — nothing
/// could be substituted. The behaviour now lives in focused repositories; this
/// class only forwards.
///
/// It exists so the split could land as a pure structural change with the
/// existing call sites untouched. The next step is injecting the repositories
/// directly and deleting this class. Prefer taking a repository in new code;
/// do not add methods here.
class StorageService {
  StorageService(AppDatabase db)
      : records = PuzzleRecordRepository(db),
        profiles = ProfileRepository(db),
        preferences = PreferencesRepository(db),
        savedGames = SavedGameRepository(db);

  final PuzzleRecordRepository records;
  final ProfileRepository profiles;
  final PreferencesRepository preferences;
  final SavedGameRepository savedGames;

  static StorageService? _instance;
  static StorageService get instance {
    assert(
      _instance != null,
      'StorageService.init(db) must be called before use',
    );
    return _instance!;
  }

  static void init(AppDatabase db) => _instance = StorageService(db);

  // ── puzzle records ─────────────────────────────────────────────────

  Future<int> saveRecord(PuzzleRecordsCompanion record) =>
      records.saveRecord(record);
  Future<List<PuzzleRecord>> getAllRecords() => records.getAllRecords();
  Future<List<PuzzleRecord>> getRecordsForDifficulty(String difficulty) =>
      records.getRecordsForDifficulty(difficulty);
  Future<List<PuzzleRecord>> getRecentRecords(int days) =>
      records.getRecentRecords(days);
  Future<PuzzleRecord?> getBestRecord(String difficulty) =>
      records.getBestRecord(difficulty);
  Future<bool> hasCompletedDailyToday() => records.hasCompletedDailyToday();
  Future<PuzzleRecord?> getTodayDailyRecord() => records.getTodayDailyRecord();
  Future<int> getRecordCount() => records.getRecordCount();
  Future<double> getAvgQualityScore() => records.getAvgQualityScore();
  Future<Map<String, int>> getCountByDifficulty() =>
      records.getCountByDifficulty();
  Future<Map<String, double>> getAvgQualityByDifficulty() =>
      records.getAvgQualityByDifficulty();
  Future<Map<String, int>> getBestTimeByDifficulty() =>
      records.getBestTimeByDifficulty();
  Future<int> getDailyCount() => records.getDailyCount();

  // ── profile ────────────────────────────────────────────────────────

  Future<void> updateProfile(PlayerProfilesCompanion profile) =>
      profiles.updateProfile(profile);
  Future<PlayerProfile> getProfile() => profiles.getProfile();
  Future<void> updateStreak() => profiles.updateStreak();
  bool canUseStreakFreeze(PlayerProfile profile) =>
      profiles.canUseStreakFreeze(profile);
  Future<void> incrementStarted() => profiles.incrementStarted();

  // ── preferences ────────────────────────────────────────────────────

  Future<void> updatePreferences(GamePreferencesTableCompanion prefs) =>
      preferences.updatePreferences(prefs);
  Future<void> markOnboardingSeen() => preferences.markOnboardingSeen();
  Future<GamePreferencesTableData> getPreferences() =>
      preferences.getPreferences();

  // ── saved game ─────────────────────────────────────────────────────

  Stream<SavedGame?> get savedGameStream => savedGames.savedGameStream;
  Future<void> saveGame(SavedGamesCompanion game) => savedGames.saveGame(game);
  Future<SavedGame?> getSavedGame() => savedGames.getSavedGame();
  Future<void> deleteSavedGame() => savedGames.deleteSavedGame();

  // ── data management ────────────────────────────────────────────────

  /// Fans out across every repository.
  ///
  /// The old version deleted `saved_games` directly and never fired the saved
  /// game stream, so the home screen kept rendering a resume bar for a game
  /// that had just been erased. Going through the repository fixes that, and
  /// means a table added later cannot be silently missed by a factory reset.
  Future<void> resetAllData() async {
    Log.storage('resetAllData');
    await records.deleteAll();
    await savedGames.deleteAll();
    await profiles.reset();
  }
}

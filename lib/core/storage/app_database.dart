import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

// ── Tables ─────────────────────────────────────────────────────────

class PuzzleRecords extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId => text()(); // date string for daily, timestamp_random for quick play
  TextColumn get difficulty => text()(); // easy | medium | hard | expert
  BoolColumn get isDaily => boolean().withDefault(const Constant(false))();
  IntColumn get timeSeconds => integer()();
  IntColumn get hintsUsed => integer().withDefault(const Constant(0))();
  IntColumn get mistakes => integer().withDefault(const Constant(0))();
  DateTimeColumn get completedAt => dateTime()();

  // Velocity: comma-separated ints of seconds between placements
  TextColumn get solveTimes => text().withDefault(const Constant(''))();

  IntColumn get undosUsed => integer().withDefault(const Constant(0))();
  BoolColumn get usedNotes => boolean().withDefault(const Constant(false))();
  IntColumn get longestPauseSeconds => integer().withDefault(const Constant(0))();

  // Comma-separated cell indices (0-80) where mistakes happened
  TextColumn get mistakeCells => text().withDefault(const Constant(''))();

  RealColumn get qualityScore => real().withDefault(const Constant(0.0))();
  IntColumn get formulaVersion => integer().withDefault(const Constant(1))();
}

class PlayerProfiles extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  TextColumn get displayName => text().withDefault(const Constant('anon'))();
  IntColumn get currentStreak => integer().withDefault(const Constant(0))();
  IntColumn get longestStreak => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastPlayedDate => dateTime().nullable()();
  IntColumn get totalSolved => integer().withDefault(const Constant(0))();
  IntColumn get totalStarted => integer().withDefault(const Constant(0))();
  TextColumn get preferredDifficulty => text().withDefault(const Constant('medium'))();
  DateTimeColumn get lastFreezeUsedDate => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class GamePreferencesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get autoRemoveNotes => boolean().withDefault(const Constant(true))();
  BoolColumn get highlightMatching => boolean().withDefault(const Constant(true))();
  BoolColumn get showTimer => boolean().withDefault(const Constant(false))();
  IntColumn get mistakeLimit => integer().withDefault(const Constant(0))(); // 0 = off
  TextColumn get theme => text().withDefault(const Constant('paper'))(); // paper | dark | amoled
  BoolColumn get digitFirstInput => boolean().withDefault(const Constant(false))();
  BoolColumn get hasSeenOnboarding => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}

class SavedGames extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId => text()();
  TextColumn get difficulty => text()();
  BoolColumn get isDaily => boolean()();
  TextColumn get givenCells => text()();       // comma-separated int[81]
  TextColumn get solutionCells => text()();    // comma-separated int[81]
  TextColumn get boardCells => text()();       // comma-separated int[81]
  TextColumn get notes => text()();            // JSON: {"cellIndex": [1,3,5]}
  IntColumn get elapsedSeconds => integer()();
  IntColumn get hintsRemaining => integer()();
  IntColumn get mistakeCount => integer()();
  BoolColumn get isNotesMode => boolean()();
  DateTimeColumn get savedAt => dateTime()();
}

// ── Database ───────────────────────────────────────────────────────

@DriftDatabase(tables: [PuzzleRecords, PlayerProfiles, GamePreferencesTable, SavedGames])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// For tests — accepts an in-memory executor.
  AppDatabase.forTesting(super.executor);

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 9;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'no_bs_sudoku',
      native: const DriftNativeOptions(shareAcrossIsolates: true),
    );
  }

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await into(playerProfiles).insert(
            PlayerProfilesCompanion.insert(),
          );
          await into(gamePreferencesTable).insert(
            GamePreferencesTableCompanion.insert(),
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_puzzle_records_difficulty ON puzzle_records(difficulty)',
          );
          await customStatement(
            'CREATE INDEX IF NOT EXISTS idx_puzzle_records_completed_at ON puzzle_records(completed_at)',
          );
        },
        onUpgrade: (m, from, to) async {
          // from < 2 used to create daily_puzzle_cache. Both it and
          // sync_queue_items were never written to by any code path and are
          // dropped at v9 below, so there is nothing to create.
          if (from < 3) {
            await m.createTable(savedGames);
          }
          if (from < 4) {
            await customStatement(
              'ALTER TABLE puzzle_records ADD COLUMN formula_version INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (from < 5) {
            await customStatement(
              'ALTER TABLE player_profiles ADD COLUMN last_freeze_used_date INTEGER',
            );
          }
          if (from < 6) {
            await customStatement(
              'ALTER TABLE game_preferences_table ADD COLUMN digit_first_input INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (from < 7) {
            await customStatement(
              'ALTER TABLE game_preferences_table ADD COLUMN has_seen_onboarding INTEGER NOT NULL DEFAULT 0',
            );
          }
          if (from < 8) {
            // Mark existing users as having seen onboarding so they don't see it
            // on upgrade. Uses profile total_solved as the signal.
            await customStatement(
              'UPDATE game_preferences_table SET has_seen_onboarding = 1 '
              'WHERE (SELECT total_solved FROM player_profiles WHERE id = 1) > 0',
            );
            // Indexes for common query patterns on puzzle_records
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_puzzle_records_difficulty ON puzzle_records(difficulty)',
            );
            await customStatement(
              'CREATE INDEX IF NOT EXISTS idx_puzzle_records_completed_at ON puzzle_records(completed_at)',
            );
          }
          if (from < 9) {
            // daily_puzzle_cache and sync_queue_items were declared but never
            // written to by any code path — zero callers for every accessor.
            // IF EXISTS because a device that upgraded from v1 never had
            // daily_puzzle_cache created in the first place.
            await customStatement('DROP TABLE IF EXISTS daily_puzzle_cache');
            await customStatement('DROP TABLE IF EXISTS sync_queue_items');
          }
        },
      );
}

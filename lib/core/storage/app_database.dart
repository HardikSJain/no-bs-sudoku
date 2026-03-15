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

  @override
  Set<Column> get primaryKey => {id};
}

class GamePreferencesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get autoRemoveNotes => boolean().withDefault(const Constant(true))();
  BoolColumn get highlightMatching => boolean().withDefault(const Constant(true))();
  BoolColumn get showTimer => boolean().withDefault(const Constant(false))();
  IntColumn get mistakeLimit => integer().withDefault(const Constant(0))(); // 0 = off
  TextColumn get theme => text().withDefault(const Constant('dark'))(); // dark | amoled

  @override
  Set<Column> get primaryKey => {id};
}

class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // "completion"
  TextColumn get payload => text()(); // JSON
  DateTimeColumn get queuedAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
}

// ── Database ───────────────────────────────────────────────────────

@DriftDatabase(tables: [PuzzleRecords, PlayerProfiles, GamePreferencesTable, SyncQueueItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 1;

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
          // Seed singleton rows
          await into(playerProfiles).insert(
            PlayerProfilesCompanion.insert(),
          );
          await into(gamePreferencesTable).insert(
            GamePreferencesTableCompanion.insert(),
          );
        },
      );
}

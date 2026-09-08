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

  /// Which timing code produced [solveTimes].
  ///
  /// Version 1 measured inter-placement gaps against the wall clock, so a
  /// single overnight backgrounding wrote a 28800-second "thinking time".
  /// Stuck detection derives a personal p90 from these deltas, and one such
  /// value drags that threshold up permanently — the nudge would then never
  /// fire again for that player. Version 1 records are excluded from the
  /// pool rather than trusted.
  ///
  /// Deliberately separate from [formulaVersion], which is about the quality
  /// formula. Two unrelated things sharing one marker is how a later change
  /// to either quietly corrupts the other.
  IntColumn get timingVersion => integer().withDefault(const Constant(1))();
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

/// One row per technique the player has met.
///
/// Kept out of PlayerProfiles because that table is a single aggregate row
/// and this is genuinely per-technique — twelve columns times five metrics
/// would be sixty columns and a migration every time a rule is added.
class TechniqueMasteryTable extends Table {
  /// The Technique enum name. Stable, and the same string the analytics and
  /// the saved-game techniques column already use.
  TextColumn get technique => text()();

  IntColumn get drillsAttempted => integer().withDefault(const Constant(0))();
  IntColumn get drillsUnaided => integer().withDefault(const Constant(0))();

  /// Times it appeared in a puzzle the player completed.
  IntColumn get encountered => integer().withDefault(const Constant(0))();

  /// Times a hint explained it.
  IntColumn get assisted => integer().withDefault(const Constant(0))();

  IntColumn get bestSeconds => integer().nullable()();
  DateTimeColumn get lastPractisedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {technique};
}

class GamePreferencesTable extends Table {
  IntColumn get id => integer().withDefault(const Constant(1))();
  BoolColumn get autoRemoveNotes => boolean().withDefault(const Constant(true))();
  BoolColumn get highlightMatching => boolean().withDefault(const Constant(true))();
  BoolColumn get showTimer => boolean().withDefault(const Constant(false))();
  IntColumn get mistakeLimit => integer().withDefault(const Constant(0))(); // 0 = off
  /// Dead since the app dropped to a single theme. Kept rather than migrated
  /// away: SQLite cannot drop a column without rewriting the table, and this
  /// buys nothing. Nothing reads or writes it.
  TextColumn get theme => text().withDefault(const Constant('paper'))();
  BoolColumn get digitFirstInput => boolean().withDefault(const Constant(false))();
  BoolColumn get hasSeenOnboarding => boolean().withDefault(const Constant(false))();

  /// The three coaching switches. Defaults reproduce today's experience
  /// except that hints now explain, which is strictly more informative and
  /// cannot burn a scarce resource.
  BoolColumn get hintsExplain => boolean().withDefault(const Constant(true))();
  BoolColumn get flagMistakesInstantly =>
      boolean().withDefault(const Constant(true))();
  /// Off by default, and turned off for everyone at v18.
  ///
  /// It fired after ninety seconds without a placement, up to three times a
  /// puzzle, and wrote a hint nobody asked for into the panel. Reported as
  /// exactly what it is: an interruption, in a game whose whole activity is
  /// sitting still and thinking. Ninety seconds of thought is not being
  /// stuck.
  ///
  /// Kept rather than deleted, because for a beginner staring at a wall it
  /// is genuinely the right behaviour — it is just not something to do to
  /// somebody who never asked.
  BoolColumn get nudgeWhenStuck => boolean().withDefault(const Constant(false))();

  /// Off by default, deliberately. A post-solve technique debrief reads as an
  /// interruption to most players; for the audience that wants it, it is the
  /// payoff. It must never appear unbidden.
  BoolColumn get showSolvePath =>
      boolean().withDefault(const Constant(false))();

  /// When the store rating prompt was last requested.
  ///
  /// Written whether or not the system actually showed anything, because it
  /// does not tell us — and treating "not shown" as "not asked" means asking
  /// on every single completion.
  DateTimeColumn get lastReviewRequestAt => dateTime().nullable()();

  /// A random string made once on this device, attached to feedback so that
  /// three reports of the same bug from the same person do not read as three
  /// people.
  ///
  /// Not a device id and not derived from one: it is random, it lives only
  /// here, no other app can see it, and clearing the app's data throws it
  /// away. Null until the first time feedback is opened — there is no reason
  /// to mint one for somebody who never writes in.
  TextColumn get installId => text().nullable()();

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
  /// Dead since hints stopped being a scarce resource. Kept because the
  /// column is NOT NULL with no default, and dropping it would mean a table
  /// rewrite for nothing — every write puts a constant 0 here.
  IntColumn get hintsRemaining => integer()();

  /// How many hints were asked for, and how deep they were pushed. Without
  /// these a resumed puzzle would score as though it had been solved unaided.
  IntColumn get hintsUsed => integer().withDefault(const Constant(0))();
  IntColumn get hintDepthTotal => integer().withDefault(const Constant(0))();
  IntColumn get mistakeCount => integer()();
  BoolColumn get isNotesMode => boolean()();
  DateTimeColumn get savedAt => dateTime()();

  // ── resume fidelity (v10) ────────────────────────────────────────
  // Without these, backgrounding the app destroyed the undo stack and reset
  // every velocity counter, so quality score and velocity analysis were wrong
  // for any resumed puzzle — and IntelligenceEngine acts on that data.
  // All default to empty so the migration is additive and a pre-v10 save
  // simply restores with no history.

  /// Versioned JSON envelope from GameHistoryCodec.
  TextColumn get history => text().withDefault(const Constant(''))();

  /// Comma-separated inter-placement deltas, in elapsed seconds.
  TextColumn get placementDeltas => text().withDefault(const Constant(''))();

  /// Comma-separated cell indices (0-80) where a mistake was made.
  TextColumn get mistakeCells => text().withDefault(const Constant(''))();

  IntColumn get undoCount => integer().withDefault(const Constant(0))();
  BoolColumn get usedNotes => boolean().withDefault(const Constant(false))();
  IntColumn get longestPauseSeconds =>
      integer().withDefault(const Constant(0))();

  /// Comma-separated Technique names. Lost on resume before v10, so a
  /// resumed puzzle showed an empty puzzleDna on the complete screen.
  ///
  /// Names written by an older build no longer resolve and are dropped on
  /// read, which costs the complete screen one line rather than failing the
  /// whole restore.
  TextColumn get techniques => text().withDefault(const Constant(''))();
}

// ── Database ───────────────────────────────────────────────────────

@DriftDatabase(tables: [
  PuzzleRecords,
  PlayerProfiles,
  GamePreferencesTable,
  SavedGames,
  TechniqueMasteryTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._() : super(_openConnection());

  /// For tests — accepts an in-memory executor.
  AppDatabase.forTesting(super.executor);

  static AppDatabase? _instance;
  static AppDatabase get instance => _instance ??= AppDatabase._();

  @override
  int get schemaVersion => 18;

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
          if (from < 10) {
            // Resume fidelity. Additive with defaults, so an existing save
            // restores exactly as before minus the history it never had.
            for (final stmt in const [
              "ALTER TABLE saved_games ADD COLUMN history TEXT NOT NULL DEFAULT ''",
              "ALTER TABLE saved_games ADD COLUMN placement_deltas TEXT NOT NULL DEFAULT ''",
              "ALTER TABLE saved_games ADD COLUMN mistake_cells TEXT NOT NULL DEFAULT ''",
              'ALTER TABLE saved_games ADD COLUMN undo_count INTEGER NOT NULL DEFAULT 0',
              // Boolean columns need drift's CHECK constraint, or an upgraded
              // database ends up with a different schema than a fresh install.
              'ALTER TABLE saved_games ADD COLUMN used_notes INTEGER NOT NULL '
                  'DEFAULT 0 CHECK (used_notes IN (0, 1))',
              'ALTER TABLE saved_games ADD COLUMN longest_pause_seconds INTEGER NOT NULL DEFAULT 0',
              "ALTER TABLE saved_games ADD COLUMN techniques TEXT NOT NULL DEFAULT ''",
            ]) {
              await customStatement(stmt);
            }
          }
          if (from < 17) {
            await customStatement(
              'ALTER TABLE game_preferences_table '
              'ADD COLUMN install_id TEXT NULL',
            );
          }
          if (from < 16) {
            await customStatement(
              'ALTER TABLE game_preferences_table '
              'ADD COLUMN last_review_request_at INTEGER NULL',
            );
          }
          if (from < 15) {
            await m.createTable(techniqueMasteryTable);
          }
          if (from < 14) {
            await customStatement(
              'ALTER TABLE game_preferences_table ADD COLUMN show_solve_path '
              'INTEGER NOT NULL DEFAULT 0 CHECK (show_solve_path IN (0, 1))',
            );
          }
          if (from < 13) {
            // Everything already recorded predates the marker, so it stays at
            // version 1 and is treated as untrusted for timing.
            await customStatement(
              'ALTER TABLE puzzle_records ADD COLUMN timing_version '
              'INTEGER NOT NULL DEFAULT 1',
            );
          }
          if (from < 12) {
            // The coaching switches. All default on, so an existing player
            // sees the new behaviour without having to go and find it.
            for (final stmt in const [
              'ALTER TABLE game_preferences_table ADD COLUMN hints_explain '
                  'INTEGER NOT NULL DEFAULT 1 CHECK (hints_explain IN (0, 1))',
              'ALTER TABLE game_preferences_table ADD COLUMN '
                  'flag_mistakes_instantly INTEGER NOT NULL DEFAULT 1 '
                  'CHECK (flag_mistakes_instantly IN (0, 1))',
              'ALTER TABLE game_preferences_table ADD COLUMN nudge_when_stuck '
                  'INTEGER NOT NULL DEFAULT 1 CHECK (nudge_when_stuck IN (0, 1))',
            ]) {
              await customStatement(stmt);
            }
          }
          if (from < 11) {
            // Hint accounting. A save written before this restores with zero
            // depth, which reads as "solved unaided" — the same thing it
            // reported before the columns existed, so nobody's score moves.
            for (final stmt in const [
              'ALTER TABLE saved_games ADD COLUMN hints_used INTEGER NOT NULL DEFAULT 0',
              'ALTER TABLE saved_games ADD COLUMN hint_depth_total INTEGER NOT NULL DEFAULT 0',
            ]) {
              await customStatement(stmt);
            }
          }

          // Last, and it has to be last.
          //
          // Every other block here adds a column, so they are independent and
          // their order is only a style choice. This one *writes* to a column
          // that the `from < 12` block above creates, so on a v8 database it
          // has to run after it. Putting it at the top with the other recent
          // work is exactly what I did first, and the migration test caught
          // it: "no such column: nudge_when_stuck".
          // Guarded on the destination as well as the origin, which the
          // older blocks above are not. They only ever add a column, so
          // running one early is invisible; this one *replaces the table*, so
          // applying it during a migration that was only meant to reach 17
          // leaves a database that does not match version 17. The schema
          // verifier tests exactly that.
          if (from < 18 && to >= 18) {
            // Everyone off, not just new installs.
            //
            // The column has been on by default since v12, so an enabled row
            // records an inherited default rather than a decision — almost
            // nobody went looking for this switch. Turning off an
            // interruption cannot hurt someone who wanted it: they open the
            // app, nothing interrupts them, and the switch is still there.
            // The reverse is not true, which is what makes this the safe
            // direction to be wrong in.
            //
            // A plain UPDATE was the first attempt and it is not enough:
            // SQLite cannot alter a column's DEFAULT, so the values would
            // have moved while an upgraded database kept `DEFAULT 1` and a
            // fresh install had `DEFAULT 0`. Same divergence the v10 boolean
            // columns were careful about, and the schema verifier caught it.
            // Rebuilding the table takes the new default and rewrites every
            // existing row in one step.
            await m.alterTable(
              TableMigration(
                gamePreferencesTable,
                columnTransformer: {
                  gamePreferencesTable.nudgeWhenStuck: const Constant(false),
                },
              ),
            );
          }
        },
      );
}

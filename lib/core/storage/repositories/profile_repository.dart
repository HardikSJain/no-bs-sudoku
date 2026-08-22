import 'package:drift/drift.dart';

import '../../daily_key.dart';
import '../../logger.dart';
import '../app_database.dart';

/// Everything that reads or writes `player_profiles`: streaks, totals,
/// the freeze, and the preferred difficulty.
class ProfileRepository {
  ProfileRepository(this._db);

  final AppDatabase _db;

  Future<void> updateProfile(PlayerProfilesCompanion profile) async {
    await (_db.update(_db.playerProfiles)..where((t) => t.id.equals(1)))
        .write(profile);
  }

  Future<PlayerProfile> getProfile() async {
    final row = await (_db.select(_db.playerProfiles)
          ..where((t) => t.id.equals(1)))
        .getSingleOrNull();
    if (row != null) return row;
    // Seed on first access.
    await _db.into(_db.playerProfiles).insert(PlayerProfilesCompanion.insert());
    return (_db.select(_db.playerProfiles)..where((t) => t.id.equals(1)))
        .getSingle();
  }

  Future<void> updateStreak() async {
    final profile = await getProfile();
    final todayDate = todayUtc();
    final lastPlayed = profile.lastPlayedDate;

    int newStreak = profile.currentStreak;

    if (lastPlayed != null) {
      // dayUtc, not DateTime(y, m, d) — the latter builds a *local* midnight
      // from a stored UTC date's components and then diffs it against a UTC
      // one. At UTC+05:30 that 5.5 hour skew can flip inDays by one and break
      // a streak a day early.
      final lastDate = dayUtc(lastPlayed);
      final diff = todayDate.difference(lastDate).inDays;

      if (diff == 0) {
        // Same day — streak unchanged, but totalSolved still increments below.
      } else if (diff == 1) {
        newStreak += 1;
      } else if (diff == 2 && canUseStreakFreeze(profile)) {
        // Missed exactly one day — auto-apply the freeze.
        newStreak += 1;
        Log.streakFreezeUsed();
        await updateProfile(
          PlayerProfilesCompanion(lastFreezeUsedDate: Value(todayDate)),
        );
      } else {
        newStreak = 1;
      }
    } else {
      newStreak = 1;
    }

    final newLongest =
        newStreak > profile.longestStreak ? newStreak : profile.longestStreak;

    await updateProfile(PlayerProfilesCompanion(
      currentStreak: Value(newStreak),
      longestStreak: Value(newLongest),
      lastPlayedDate: Value(todayDate),
      totalSolved: Value(profile.totalSolved + 1),
    ));

    Log.streakUpdated(streak: newStreak);
  }

  /// One free freeze per 7-day window.
  bool canUseStreakFreeze(PlayerProfile profile) {
    final lastFreeze = profile.lastFreezeUsedDate;
    if (lastFreeze == null) return true;
    return todayUtc().difference(dayUtc(lastFreeze)).inDays >= 7;
  }

  Future<void> incrementStarted() async {
    final profile = await getProfile();
    await updateProfile(
      PlayerProfilesCompanion(totalStarted: Value(profile.totalStarted + 1)),
    );
  }

  /// Back to a fresh profile. Used by the factory reset.
  Future<void> reset() => updateProfile(PlayerProfilesCompanion(
        displayName: const Value('anon'),
        currentStreak: const Value(0),
        longestStreak: const Value(0),
        lastPlayedDate: const Value(null),
        totalSolved: const Value(0),
        totalStarted: const Value(0),
        preferredDifficulty: const Value('medium'),
        lastFreezeUsedDate: const Value(null),
      ));
}

/// Timezone-independent keys for the daily puzzle.
///
/// The daily is supposed to be the same puzzle for everyone, everywhere — the
/// README says so. It was not. `generateDaily` seeded off device-local
/// `DateTime.now()`, so two players in different zones got different puzzles
/// for the same calendar day.
///
/// Worse, the app disagreed with itself. The puzzle id, the
/// completed-today check, the streak bucket, the re-engagement copy and the
/// date on the home card were each derived from local time independently. In
/// UTC+5:30 that left a five-and-a-half hour window every day where the app
/// believed today's daily was unplayed while the player had just finished it.
///
/// Every one of those reads goes through this file now. Consequence worth
/// knowing: the new daily lands at midnight UTC, which is 05:30 in India
/// rather than local midnight. That is the price of "same for everyone".
library;

/// Midnight UTC for the current instant. Use for day-bucketing: streaks,
/// days-since-last-play, freeze eligibility.
DateTime todayUtc() {
  final now = DateTime.now().toUtc();
  return DateTime.utc(now.year, now.month, now.day);
}

/// Midnight UTC for [date], for bucketing a stored timestamp.
DateTime dayUtc(DateTime date) {
  final d = date.toUtc();
  return DateTime.utc(d.year, d.month, d.day);
}

/// The `puzzleId` of a daily, e.g. `2026-08-22`. Always UTC.
///
/// This string is the join key between a generated daily and its stored
/// record, so it must be built here and nowhere else.
String dailyPuzzleId([DateTime? date]) {
  final d = (date ?? DateTime.now()).toUtc();
  return '${d.year}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';
}

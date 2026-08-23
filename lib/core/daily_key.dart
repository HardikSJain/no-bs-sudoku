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

/// How far back the daily archive goes.
///
/// Generation is deterministic, so any date in history could be offered and
/// none of it would cost anything to store. Ninety days is a product choice
/// rather than a technical limit: the archive exists so somebody who was away
/// for a fortnight can catch up, not so a new player can farm three years of
/// backlog. It is also short enough that the calendar stays a page you can
/// read rather than a scroll you get lost in.
///
/// Said plainly in the UI. A limit you hide is a dark pattern; a limit you
/// state is a scope.
const int dailyArchiveDays = 90;

/// Every date the archive offers, oldest first, ending with today.
List<DateTime> dailyArchiveDates() {
  final today = todayUtc();
  return [
    for (var i = dailyArchiveDays - 1; i >= 0; i--)
      today.subtract(Duration(days: i)),
  ];
}

/// Whether [date] is a day the archive will hand out a puzzle for.
bool isInDailyArchive(DateTime date) {
  final day = dayUtc(date);
  final today = todayUtc();
  if (day.isAfter(today)) return false;
  return today.difference(day).inDays < dailyArchiveDays;
}

/// Parses a `2026-08-22` id back to its UTC midnight, or null if it is not
/// one. Route parameters arrive as strings and are not to be trusted.
DateTime? parseDailyPuzzleId(String id) {
  final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(id);
  if (match == null) return null;
  final y = int.parse(match.group(1)!);
  final m = int.parse(match.group(2)!);
  final d = int.parse(match.group(3)!);
  if (m < 1 || m > 12 || d < 1 || d > 31) return null;
  final parsed = DateTime.utc(y, m, d);
  // Rejects 2026-02-31, which DateTime.utc quietly rolls into March.
  if (parsed.month != m || parsed.day != d) return null;
  return parsed;
}

import 'dart:math';

import '../../engine/sudoku_solver.dart';
import '../storage/app_database.dart';
import '../storage/storage_service.dart';

class IntelligenceEngine {
  final StorageService _storage;

  IntelligenceEngine(this._storage);

  // ── Difficulty recommendation ──────────────────────────────────────

  Future<Difficulty> recommendDifficulty() async {
    final profile = await _storage.getProfile();
    final current = Difficulty.fromName(profile.preferredDifficulty);
    final currentIdx = Difficulty.values.indexOf(current);

    final records = await _storage.getRecordsForDifficulty(current.name);
    if (records.length < 5) return current;

    final last5 = records.take(5).toList();
    final highCount = last5.where((r) => r.qualityScore > 80).length;
    final lowCount = last5.where((r) => r.qualityScore < 45).length;

    if (highCount >= 3 && currentIdx < Difficulty.values.length - 1) {
      final next = Difficulty.values[currentIdx + 1];
      final nextRecords = await _storage.getRecordsForDifficulty(next.name);
      if (nextRecords.isNotEmpty) return next;
      return current;
    }

    if (lowCount >= 3 && currentIdx > 0) {
      return Difficulty.values[currentIdx - 1];
    }

    return current;
  }

  // ── Best time of day ───────────────────────────────────────────────

  Future<String?> bestTimeOfDay() async {
    final records = await _storage.getAllRecords();
    if (records.length < 3) return null;

    final buckets = <String, List<double>>{};
    for (final r in records) {
      final hour = r.completedAt.hour;
      final bucket = _hourBucket(hour);
      buckets.putIfAbsent(bucket, () => []).add(r.qualityScore);
    }

    String? best;
    double bestAvg = 0;

    for (final entry in buckets.entries) {
      if (entry.value.length < 3) continue;
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      if (avg > bestAvg) {
        bestAvg = avg;
        best = entry.key;
      }
    }

    return best;
  }

  String _hourBucket(int hour) {
    if (hour >= 6 && hour < 12) return 'morning';
    if (hour >= 12 && hour < 18) return 'afternoon';
    if (hour >= 18 && hour < 23) return 'evening';
    return 'night';
  }

  // ── Consistency score ──────────────────────────────────────────────

  Future<int> consistencyScore() async {
    final records = await _storage.getRecentRecords(30);
    if (records.isEmpty) return 0;

    final days = <DateTime>{};
    for (final r in records) {
      days.add(DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day));
    }

    return ((days.length / 30) * 100).round().clamp(0, 100);
  }

  // ── Longest clean run ──────────────────────────────────────────────

  Future<int> longestCleanRun() async {
    final records = await _storage.getAllRecords();
    if (records.isEmpty) return 0;

    // Records come sorted by completedAt desc — reverse for chronological
    final sorted = records.reversed.toList();
    int longest = 0;
    int current = 0;

    for (final r in sorted) {
      if (r.mistakes == 0) {
        current++;
        longest = max(longest, current);
      } else {
        current = 0;
      }
    }

    return longest;
  }

  // ── Performance trend ──────────────────────────────────────────────

  Future<String> performanceTrend() async {
    final thisWeek = await _storage.getRecentRecords(7);
    final lastWeek = await _avgQualityForPeriod(14, 7);

    if (thisWeek.length < 3) return 'insufficient_data';

    final thisAvg =
        thisWeek.map((r) => r.qualityScore).reduce((a, b) => a + b) /
            thisWeek.length;

    if (lastWeek == null) return 'insufficient_data';

    final delta = thisAvg - lastWeek;
    if (delta > 5) return 'improving';
    if (delta < -5) return 'declining';
    return 'steady';
  }

  Future<double?> _avgQualityForPeriod(int daysAgo, int daysRecent) async {
    final all = await _storage.getRecentRecords(daysAgo);
    final cutoff = DateTime.now().subtract(Duration(days: daysRecent));
    final older = all.where((r) => r.completedAt.isBefore(cutoff)).toList();
    if (older.length < 3) return null;
    return older.map((r) => r.qualityScore).reduce((a, b) => a + b) /
        older.length;
  }

  // ── Daily insight ──────────────────────────────────────────────────

  Future<String?> dailyInsight() async {
    final profile = await _storage.getProfile();
    if (profile.totalSolved < 3) return null;

    final insights = <String>[];

    // 1. Trend improving + streak > 5
    if (profile.currentStreak > 5) {
      final trend = await performanceTrend();
      if (trend == 'improving') {
        final thisWeek = await _storage.getRecentRecords(7);
        final lastWeekAvg = await _avgQualityForPeriod(14, 7);
        if (thisWeek.isNotEmpty && lastWeekAvg != null && lastWeekAvg > 0) {
          final thisAvg = thisWeek.map((r) => r.qualityScore).reduce((a, b) => a + b) / thisWeek.length;
          final delta = ((thisAvg - lastWeekAvg) / lastWeekAvg * 100).round();
          if (delta > 0) {
            insights.add('on a roll. quality up $delta% this week.');
          }
        }
      }
    }

    // 2. Best time of day
    final tod = await bestTimeOfDay();
    if (tod != null) {
      insights.add('you solve best in the $tod.');
    }

    // 3. Longest clean run > 5
    final cleanRun = await longestCleanRun();
    if (cleanRun > 5) {
      insights.add('$cleanRun puzzles in a row with zero mistakes.');
    }

    // 4. Consistency > 80%
    final consistency = await consistencyScore();
    if (consistency > 80) {
      final records = await _storage.getRecentRecords(30);
      final days = <DateTime>{};
      for (final r in records) {
        days.add(DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day));
      }
      insights.add('played ${days.length} of the last 30 days.');
    }

    // 5. Personal best in last 24h
    final recentRecords = await _storage.getRecentRecords(1);
    if (recentRecords.isNotEmpty) {
      for (final r in recentRecords) {
        final best = await _storage.getBestRecord(r.difficulty);
        if (best != null && best.id == r.id) {
          final mins = r.timeSeconds ~/ 60;
          final secs = r.timeSeconds % 60;
          final timeStr = '$mins:${secs.toString().padLeft(2, '0')}';
          insights.add('new personal best. $timeStr on ${r.difficulty}.');
          break;
        }
      }
    }

    // 6. Always uses notes on expert
    final expertRecords = await _storage.getRecordsForDifficulty(Difficulty.expert.name);
    if (expertRecords.length >= 3 && expertRecords.every((r) => r.usedNotes)) {
      insights.add('notes mode: your expert strategy.');
    }

    // 7. High avg undos on hard
    final hardRecords = await _storage.getRecordsForDifficulty(Difficulty.hard.name);
    if (hardRecords.length >= 5) {
      final last5 = hardRecords.take(5).toList();
      final avgUndos = last5.map((r) => r.undosUsed).reduce((a, b) => a + b) / 5;
      if (avgUndos > 4) {
        insights.add('lots of undos on hard. try notes mode.');
      }
    }

    // 8. Completion rate < 60%
    if (profile.totalStarted > 0) {
      final pct = (profile.totalSolved / profile.totalStarted * 100).round();
      if (pct < 60) {
        insights.add('finishing $pct% of puzzles started.');
      }
    }

    if (insights.isEmpty) return null;

    // Rotate deterministically by day
    final dayOfYear = DateTime.now().difference(DateTime(DateTime.now().year)).inDays;
    return insights[dayOfYear % insights.length];
  }

  // ── Focus time ─────────────────────────────────────────────────────

  int focusTimeSeconds(PuzzleRecord r) =>
      (r.timeSeconds - r.longestPauseSeconds).clamp(0, r.timeSeconds);
}

import 'dart:developer' as dev;

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Structured logger that writes to dart:developer + Firebase Crashlytics + Analytics.
class Log {
  Log._();

  static FirebaseCrashlytics? _crashlytics;
  static FirebaseAnalytics? _analytics;

  /// Call once after Firebase.initializeApp().
  static void init() {
    _crashlytics = FirebaseCrashlytics.instance;
    _analytics = FirebaseAnalytics.instance;
  }

  static FirebaseAnalytics? get analytics => _analytics;

  // ── Core logging ──────────────────────────────────────────────────

  static void info(String message, {String? tag}) {
    dev.log(message, name: tag ?? 'app');
    _crashlytics?.log('${tag ?? 'app'}: $message');
  }

  static void warn(String message, {String? tag, Object? error}) {
    dev.log('⚠ $message', name: tag ?? 'app', error: error);
    _crashlytics?.log('⚠ ${tag ?? 'app'}: $message');
  }

  static void error(
    String message, {
    String? tag,
    Object? error,
    StackTrace? stackTrace,
  }) {
    dev.log(
      '✗ $message',
      name: tag ?? 'app',
      error: error,
      stackTrace: stackTrace,
    );
    if (error != null) {
      _crashlytics?.recordError(
        error,
        stackTrace,
        reason: '${tag ?? 'app'}: $message',
        fatal: false,
      );
    } else {
      _crashlytics?.log('✗ ${tag ?? 'app'}: $message');
    }
  }

  static void storage(String operation, {Object? error}) {
    if (error != null) {
      Log.error('storage.$operation failed', tag: 'storage', error: error);
    } else {
      dev.log('storage.$operation', name: 'storage');
    }
  }

  // ── Crashlytics context keys ──────────────────────────────────────

  static void setGameContext({
    required String puzzleId,
    required String difficulty,
    required bool isDaily,
  }) {
    _crashlytics?.setCustomKey('puzzleId', puzzleId);
    _crashlytics?.setCustomKey('difficulty', difficulty);
    _crashlytics?.setCustomKey('isDaily', isDaily);
  }

  static void clearGameContext() {
    _crashlytics?.setCustomKey('puzzleId', '');
    _crashlytics?.setCustomKey('difficulty', '');
    _crashlytics?.setCustomKey('isDaily', false);
  }

  // ── User properties (for Firebase segmentation) ───────────────────

  static void setUserProperties({
    required String preferredDifficulty,
    required int totalSolved,
    required int currentStreak,
  }) {
    _analytics?.setUserProperty(
      name: 'preferred_difficulty',
      value: preferredDifficulty,
    );
    _analytics?.setUserProperty(
      name: 'total_solved',
      value: _bucket(totalSolved),
    );
    _analytics?.setUserProperty(
      name: 'current_streak',
      value: _bucket(currentStreak),
    );
  }

  /// Bucket numbers for user properties (Firebase limits to 36 unique values).
  static String _bucket(int n) {
    if (n == 0) return '0';
    if (n <= 5) return '1-5';
    if (n <= 20) return '6-20';
    if (n <= 50) return '21-50';
    if (n <= 100) return '51-100';
    if (n <= 500) return '101-500';
    return '500+';
  }

  // ── Analytics: core event helper ──────────────────────────────────

  static void logEvent(String name, {Map<String, Object>? params}) {
    _analytics?.logEvent(name: name, parameters: params);
  }

  // ── Analytics: game lifecycle ─────────────────────────────────────

  static void puzzleStarted({
    required String difficulty,
    required bool isDaily,
  }) {
    logEvent(
      'puzzle_started',
      params: {'difficulty': difficulty, 'is_daily': isDaily.toString()},
    );
  }

  static void puzzleCompleted({
    required String difficulty,
    required bool isDaily,
    required int timeSeconds,
    required double qualityScore,
    required int hints,
    required int mistakes,
  }) {
    logEvent(
      'puzzle_completed',
      params: {
        'difficulty': difficulty,
        'is_daily': isDaily.toString(),
        'time_seconds': timeSeconds,
        'quality_score': qualityScore.round(),
        'hints': hints,
        'mistakes': mistakes,
      },
    );
  }

  static void puzzleAbandoned({
    required String difficulty,
    required bool isDaily,
  }) {
    logEvent(
      'puzzle_abandoned',
      params: {'difficulty': difficulty, 'is_daily': isDaily.toString()},
    );
  }

  static void puzzleResumed({
    required String difficulty,
    required bool isDaily,
    required int elapsedSeconds,
  }) {
    logEvent(
      'puzzle_resumed',
      params: {
        'difficulty': difficulty,
        'is_daily': isDaily.toString(),
        'elapsed_seconds': elapsedSeconds,
      },
    );
  }

  static void puzzlePaused({
    required String difficulty,
    required int elapsedSeconds,
  }) {
    logEvent(
      'puzzle_paused',
      params: {'difficulty': difficulty, 'elapsed_seconds': elapsedSeconds},
    );
  }

  // ── Analytics: in-game actions ────────────────────────────────────

  /// One technique drill finished. Which techniques people actually practise
  /// is the question trainer mode exists to answer.
  static void drillCompleted({
    required String technique,
    required int seconds,
  }) {
    logEvent('drill_completed',
        params: {'technique': technique, 'seconds': seconds});
  }

  /// Fired when the app offered help nobody asked for. How often this lands
  /// versus how often it is dismissed is the only way to tell whether it
  /// reads as helpful or as nagging.
  static void stuckNudge({required String difficulty}) {
    logEvent('stuck_nudge', params: {'difficulty': difficulty});
  }

  /// [rung] is how far the hint was pushed — locate, narrow, explain, apply.
  /// Which rung people actually stop at is the whole question this release
  /// asks, so it is the parameter worth recording.
  static void hintUsed({
    required String difficulty,
    required String rung,
  }) {
    logEvent(
      'hint_used',
      params: {'difficulty': difficulty, 'rung': rung},
    );
  }

  static void undoUsed({required String difficulty}) {
    logEvent('undo_used', params: {'difficulty': difficulty});
  }

  static void notesToggled({required bool enabled}) {
    logEvent('notes_toggled', params: {'enabled': enabled.toString()});
  }

  // ── Analytics: navigation / engagement ────────────────────────────

  static void difficultySelected({required String difficulty}) {
    logEvent('difficulty_selected', params: {'difficulty': difficulty});
  }

  static void dailyPuzzleTapped({required bool alreadyCompleted}) {
    logEvent(
      'daily_puzzle_tapped',
      params: {'already_completed': alreadyCompleted.toString()},
    );
  }

  static void shareResult({
    required String difficulty,
    required bool isDaily,
    required int qualityScore,
  }) {
    logEvent(
      'share_result',
      params: {
        'difficulty': difficulty,
        'is_daily': isDaily.toString(),
        'quality_score': qualityScore,
      },
    );
  }

  // ── Analytics: milestones ─────────────────────────────────────────

  static void streakUpdated({required int streak}) {
    logEvent('streak_updated', params: {'streak': streak});
    // Fire milestone events at key thresholds
    if (const {7, 14, 30, 60, 100, 365}.contains(streak)) {
      logEvent('streak_milestone', params: {'streak': streak});
    }
  }

  static void personalBest({
    required String difficulty,
    required int timeSeconds,
  }) {
    logEvent(
      'personal_best',
      params: {'difficulty': difficulty, 'time_seconds': timeSeconds},
    );
  }

  static void streakFreezeUsed() {
    logEvent('streak_freeze_used');
  }

  // ── Analytics: settings & data ────────────────────────────────────

  static void settingsChanged({
    required String setting,
    required String value,
  }) {
    logEvent('settings_changed', params: {'setting': setting, 'value': value});
  }

  static void exportData() {
    logEvent('export_data');
  }

  /// The daily archive was opened.
  static void archiveOpened() => logEvent('archive_opened');

  /// A daily from the archive was started.
  ///
  /// [daysAgo] is bucketed rather than exact: the question is whether people
  /// catch up on yesterday or dig weeks back, and a raw day count would make
  /// ninety separate values out of one answer. [replay] separates catching up
  /// from re-solving something already beaten, which are different products
  /// wearing the same button.
  static void archiveDailyStarted({
    required String difficulty,
    required int daysAgo,
    required bool replay,
  }) {
    logEvent('archive_daily_started', params: {
      'difficulty': difficulty,
      'age': _bucketDaysAgo(daysAgo),
      'replay': replay.toString(),
    });
  }

  static String _bucketDaysAgo(int days) => switch (days) {
        <= 0 => 'today',
        1 => 'yesterday',
        < 7 => 'this_week',
        < 30 => 'this_month',
        _ => 'older',
      };

  /// The import screen was opened.
  static void importOpened() => logEvent('import_opened');

  /// A grid was pasted in. [accepted] is false when the text was not 81
  /// digits — which is the number worth watching, because a high refusal
  /// rate means the formats people actually copy are not the ones parsed.
  static void importPasted({required bool accepted}) {
    logEvent('import_pasted', params: {'accepted': accepted.toString()});
  }

  /// A grid was checked. The verdict distribution says whether people are
  /// mistyping, importing ambiguous grids, or hitting the search budget.
  static void importChecked({required String verdict, required int clues}) {
    logEvent('import_checked',
        params: {'verdict': verdict, 'clues': _bucketClues(clues)});
  }

  /// An imported grid was actually played.
  static void importPlayed({required int clues}) {
    logEvent('import_played', params: {'clues': _bucketClues(clues)});
  }

  static String _bucketClues(int clues) => switch (clues) {
        < 22 => 'under_22',
        < 26 => '22_25',
        < 30 => '26_29',
        < 36 => '30_35',
        _ => '36_plus',
      };

  /// A store rating prompt was requested. Whether the system showed it is
  /// not something either store reports, so this counts requests, not views.
  static void reviewRequested() {
    logEvent('review_requested');
  }

  /// A technique reached the mastered level — the milestone the practice
  /// feature exists to produce.
  static void techniqueMastered({required String technique}) {
    logEvent('technique_mastered', params: {'technique': technique});
  }

  static void dataReset() {
    logEvent('data_reset');
  }
}

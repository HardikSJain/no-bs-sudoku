import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/logger.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/storage/app_database.dart';
import '../../core/daily_key.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../engine/sudoku_generator.dart';
import '../../engine/sudoku_solver.dart';

class HomeState {
  final bool dailyCompleted;
  final int? dailyTimeSeconds;
  final Difficulty dailyDifficulty;
  final int dailyPuzzleNum;
  final int currentStreak;
  final int totalSolved;
  final int avgQuality;
  final String? insight;
  final Difficulty recommendedDifficulty;
  /// Both slots: at most one daily and at most one of anything else.
  final InProgress saved;
  final bool loaded;
  final Map<String, int> bestTimes;

  const HomeState({
    this.dailyCompleted = false,
    this.dailyTimeSeconds,
    this.dailyDifficulty = Difficulty.hard,
    this.dailyPuzzleNum = 1,
    this.currentStreak = 0,
    this.totalSolved = 0,
    this.avgQuality = 0,
    this.insight,
    this.recommendedDifficulty = Difficulty.medium,
    this.saved = InProgress.none,
    this.loaded = false,
    this.bestTimes = const {},
  });

  HomeState copyWith({
    bool? dailyCompleted,
    int? Function()? dailyTimeSeconds,
    Difficulty? dailyDifficulty,
    int? dailyPuzzleNum,
    int? currentStreak,
    int? totalSolved,
    int? avgQuality,
    String? Function()? insight,
    Difficulty? recommendedDifficulty,
    InProgress? saved,
    bool? loaded,
    Map<String, int>? bestTimes,
  }) {
    return HomeState(
      dailyCompleted: dailyCompleted ?? this.dailyCompleted,
      dailyTimeSeconds: dailyTimeSeconds != null ? dailyTimeSeconds() : this.dailyTimeSeconds,
      dailyDifficulty: dailyDifficulty ?? this.dailyDifficulty,
      dailyPuzzleNum: dailyPuzzleNum ?? this.dailyPuzzleNum,
      currentStreak: currentStreak ?? this.currentStreak,
      totalSolved: totalSolved ?? this.totalSolved,
      avgQuality: avgQuality ?? this.avgQuality,
      insight: insight != null ? insight() : this.insight,
      recommendedDifficulty: recommendedDifficulty ?? this.recommendedDifficulty,
      saved: saved ?? this.saved,
      loaded: loaded ?? this.loaded,
      bestTimes: bestTimes ?? this.bestTimes,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final PuzzleRecordRepository _records;
  final ProfileRepository _profiles;
  final SavedGameRepository _savedGames;
  final IntelligenceEngine _intelligence;
  StreamSubscription<InProgress>? _savedGameSub;

  HomeCubit({
    required PuzzleRecordRepository records,
    required ProfileRepository profiles,
    required SavedGameRepository savedGames,
    required IntelligenceEngine intelligence,
  })  : _records = records,
        _profiles = profiles,
        _savedGames = savedGames,
        _intelligence = intelligence,
        super(const HomeState()) {
    load();
    _savedGameSub = _savedGames.savedGamesStream.listen(_onSavedGamesChanged);
  }

  /// Drops saves that are no longer worth resuming, and clears them from the
  /// slot they were holding.
  ///
  /// A daily is dropped once its date falls out of the archive window — it
  /// used to be dropped the moment it was not *today's*, which quietly ate
  /// any archive daily left half-finished. Anything under thirty seconds is
  /// dropped whatever it is: a resume bar for a puzzle you glanced at is
  /// noise.
  Future<InProgress> _filter(InProgress games) async {
    var daily = games.daily;
    var other = games.other;

    if (daily != null && !isInDailyArchive(_dateOf(daily) ?? todayUtc())) {
      await _savedGames.deleteSavedGame(isDaily: true);
      daily = null;
    }
    if (daily != null && daily.elapsedSeconds < _worthResuming) {
      await _savedGames.deleteSavedGame(isDaily: true);
      daily = null;
    }
    if (other != null && other.elapsedSeconds < _worthResuming) {
      await _savedGames.deleteSavedGame(isDaily: false);
      other = null;
    }
    return InProgress(daily: daily, other: other);
  }

  static const int _worthResuming = 30;

  DateTime? _dateOf(SavedGame saved) => parseDailyPuzzleId(saved.puzzleId);

  void _onSavedGamesChanged(InProgress games) async {
    if (isClosed) return;
    final filtered = await _filter(games);
    if (isClosed) return;
    emit(state.copyWith(saved: filtered));
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _profiles.getProfile(),               // 0
        _records.getAvgQualityScore(),       // 1
        _intelligence.recommendDifficulty(), // 2
        _intelligence.dailyInsight(),        // 3
        _savedGames.getSavedGames(),         // 4
        _records.hasCompletedDailyToday(),   // 5
        _records.getDailyCount(),            // 6
        _records.getBestTimeByDifficulty(),  // 7
      ]);

      final profile = results[0] as PlayerProfile;
      final avgQualityRaw = results[1] as double;
      final recommended = results[2] as Difficulty;
      final insight = results[3] as String?;
      var saved = results[4] as InProgress;
      final todayCompleted = results[5] as bool;
      final dailyCount = results[6] as int;
      final bestTimes = results[7] as Map<String, int>;

      // Drop anything not worth resuming, and clear its slot.
      saved = await _filter(saved);

      final avgQuality = avgQualityRaw.round();

      // Daily puzzle — difficulty rotates by day of week, deterministic
      final today = todayUtc();
      final dailyDifficulty = SudokuGenerator.dailyDifficulty(today);

      // Get today's time if completed
      int? dailyTime;
      if (todayCompleted) {
        final todayRecord = await _records.getTodayDailyRecord();
        dailyTime = todayRecord?.timeSeconds;
      }

      // Puzzle number — count of unique daily completions
      final puzzleNum = todayCompleted ? dailyCount : dailyCount + 1;

      // Update preferred difficulty only if changed
      if (recommended.name != profile.preferredDifficulty) {
        await _profiles.updateProfile(
          PlayerProfilesCompanion(preferredDifficulty: Value(recommended.name)),
        );
      }

      if (isClosed) return;

      // Set user properties for Firebase segmentation
      Log.setUserProperties(
        preferredDifficulty: recommended.name,
        totalSolved: profile.totalSolved,
        currentStreak: profile.currentStreak,
      );

      emit(HomeState(
        dailyCompleted: todayCompleted,
        dailyTimeSeconds: dailyTime,
        dailyDifficulty: dailyDifficulty,
        dailyPuzzleNum: puzzleNum,
        currentStreak: profile.currentStreak,
        totalSolved: profile.totalSolved,
        avgQuality: avgQuality,
        insight: insight,
        recommendedDifficulty: recommended,
        saved: saved,
        loaded: true,
        bestTimes: bestTimes,
      ));

      // Reschedule local notifications with fresh context (fire-and-forget)
      NotificationService.schedule(records: _records, profiles: _profiles);
    } catch (_) {
      if (isClosed) return;
      emit(const HomeState(loaded: true));
    }
  }

  Future<void> dismissSavedGame({required bool isDaily}) async {
    await _savedGames.deleteSavedGame(isDaily: isDaily);
    if (isClosed) return;
    emit(state.copyWith(
      saved: isDaily
          ? InProgress(other: state.saved.other)
          : InProgress(daily: state.saved.daily),
    ));
  }

  @override
  Future<void> close() {
    _savedGameSub?.cancel();
    return super.close();
  }
}

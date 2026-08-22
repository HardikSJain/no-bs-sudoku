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
  final SavedGame? savedGame;
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
    this.savedGame,
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
    SavedGame? Function()? savedGame,
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
      savedGame: savedGame != null ? savedGame() : this.savedGame,
      loaded: loaded ?? this.loaded,
      bestTimes: bestTimes ?? this.bestTimes,
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final PuzzleRecordRepository _records;
  final ProfileRepository _profiles;
  final PreferencesRepository _preferences;
  final SavedGameRepository _savedGames;
  final IntelligenceEngine _intelligence;
  StreamSubscription<SavedGame?>? _savedGameSub;

  HomeCubit({
    required PuzzleRecordRepository records,
    required ProfileRepository profiles,
    required PreferencesRepository preferences,
    required SavedGameRepository savedGames,
    required IntelligenceEngine intelligence,
  })  : _records = records,
        _profiles = profiles,
        _preferences = preferences,
        _savedGames = savedGames,
        _intelligence = intelligence,
        super(const HomeState()) {
    load();
    _savedGameSub = _savedGames.savedGameStream.listen(_onSavedGameChanged);
  }

  /// Filters out stale/trivial saves and deletes them from DB.
  Future<SavedGame?> _filterSavedGame(SavedGame? saved) async {
    if (saved == null) return null;
    if (saved.isDaily) {
      final todayId = dailyPuzzleId();
      if (saved.puzzleId != todayId) {
        await _savedGames.deleteSavedGame();
        return null;
      }
    }
    if (saved.elapsedSeconds < 30) {
      await _savedGames.deleteSavedGame();
      return null;
    }
    return saved;
  }

  void _onSavedGameChanged(SavedGame? saved) async {
    if (isClosed) return;
    saved = await _filterSavedGame(saved);
    if (isClosed) return;
    emit(state.copyWith(savedGame: () => saved));
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _profiles.getProfile(),               // 0
        _records.getAvgQualityScore(),       // 1
        _intelligence.recommendDifficulty(), // 2
        _intelligence.dailyInsight(),        // 3
        _savedGames.getSavedGame(),             // 4
        _records.hasCompletedDailyToday(),   // 5
        _records.getDailyCount(),            // 6
        _records.getBestTimeByDifficulty(),  // 7
      ]);

      final profile = results[0] as PlayerProfile;
      final avgQualityRaw = results[1] as double;
      final recommended = results[2] as Difficulty;
      final insight = results[3] as String?;
      var saved = results[4] as SavedGame?;
      final todayCompleted = results[5] as bool;
      final dailyCount = results[6] as int;
      final bestTimes = results[7] as Map<String, int>;

      // Filter out stale/trivial saves
      saved = await _filterSavedGame(saved);

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
      final prefs = await _preferences.getPreferences();
      Log.setUserProperties(
        preferredDifficulty: recommended.name,
        totalSolved: profile.totalSolved,
        currentStreak: profile.currentStreak,
        theme: prefs.theme,
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
        savedGame: saved,
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

  Future<void> dismissSavedGame() async {
    await _savedGames.deleteSavedGame();
    if (isClosed) return;
    emit(state.copyWith(savedGame: () => null));
  }

  @override
  Future<void> close() {
    _savedGameSub?.cancel();
    return super.close();
  }
}

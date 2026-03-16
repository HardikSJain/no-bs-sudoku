import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/logger.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/storage_service.dart';
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
    );
  }
}

class HomeCubit extends Cubit<HomeState> {
  final StorageService _storage;
  final IntelligenceEngine _intelligence;
  StreamSubscription<SavedGame?>? _savedGameSub;

  HomeCubit(this._storage, this._intelligence) : super(const HomeState()) {
    load();
    _savedGameSub = _storage.savedGameStream.listen(_onSavedGameChanged);
  }

  /// Filters out stale/trivial saves and deletes them from DB.
  Future<SavedGame?> _filterSavedGame(SavedGame? saved) async {
    if (saved == null) return null;
    if (saved.isDaily) {
      final today = DateTime.now();
      final todayId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      if (saved.puzzleId != todayId) {
        await _storage.deleteSavedGame();
        return null;
      }
    }
    if (saved.elapsedSeconds < 30) {
      await _storage.deleteSavedGame();
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
        _storage.getProfile(),               // 0
        _storage.getAvgQualityScore(),       // 1
        _intelligence.recommendDifficulty(), // 2
        _intelligence.dailyInsight(),        // 3
        _storage.getSavedGame(),             // 4
        _storage.hasCompletedDailyToday(),   // 5
        _storage.getDailyCount(),            // 6
      ]);

      final profile = results[0] as PlayerProfile;
      final avgQualityRaw = results[1] as double;
      final recommended = results[2] as Difficulty;
      final insight = results[3] as String?;
      var saved = results[4] as SavedGame?;
      final todayCompleted = results[5] as bool;
      final dailyCount = results[6] as int;

      // Filter out stale/trivial saves
      saved = await _filterSavedGame(saved);

      final avgQuality = avgQualityRaw.round();

      // Daily puzzle — difficulty rotates by day of week, deterministic
      final today = DateTime.now();
      final dailyDifficulty = SudokuGenerator.dailyDifficulty(today);

      // Get today's time if completed
      int? dailyTime;
      if (todayCompleted) {
        final todayRecord = await _storage.getTodayDailyRecord();
        dailyTime = todayRecord?.timeSeconds;
      }

      // Puzzle number — count of unique daily completions
      final puzzleNum = todayCompleted ? dailyCount : dailyCount + 1;

      // Update preferred difficulty only if changed
      if (recommended.name != profile.preferredDifficulty) {
        await _storage.updateProfile(
          PlayerProfilesCompanion(preferredDifficulty: Value(recommended.name)),
        );
      }

      if (isClosed) return;

      // Set user properties for Firebase segmentation
      final prefs = await _storage.getPreferences();
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
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const HomeState(loaded: true));
    }
  }

  Future<void> dismissSavedGame() async {
    await _storage.deleteSavedGame();
    if (isClosed) return;
    emit(state.copyWith(savedGame: () => null));
  }

  @override
  Future<void> close() {
    _savedGameSub?.cancel();
    return super.close();
  }
}

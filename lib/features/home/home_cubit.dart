import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/storage_service.dart';
import '../../engine/sudoku_generator.dart';

class HomeState {
  final bool dailyCompleted;
  final int? dailyTimeSeconds;
  final String dailyDifficulty;
  final int dailyPuzzleNum;
  final int currentStreak;
  final int totalSolved;
  final int avgQuality;
  final String? insight;
  final String recommendedDifficulty;
  final SavedGame? savedGame;
  final bool loaded;

  const HomeState({
    this.dailyCompleted = false,
    this.dailyTimeSeconds,
    this.dailyDifficulty = 'hard',
    this.dailyPuzzleNum = 1,
    this.currentStreak = 0,
    this.totalSolved = 0,
    this.avgQuality = 0,
    this.insight,
    this.recommendedDifficulty = 'medium',
    this.savedGame,
    this.loaded = false,
  });
}

class HomeCubit extends Cubit<HomeState> {
  final StorageService _storage;
  final IntelligenceEngine _intelligence;
  StreamSubscription<SavedGame?>? _savedGameSub;

  HomeCubit(this._storage, this._intelligence) : super(const HomeState()) {
    load();
    _savedGameSub = _storage.savedGameStream.listen(_onSavedGameChanged);
  }

  void _onSavedGameChanged(SavedGame? saved) {
    if (isClosed) return;

    // Apply same filters as load()
    if (saved != null) {
      if (saved.isDaily) {
        final today = DateTime.now();
        final todayId =
            '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
        if (saved.puzzleId != todayId) {
          saved = null;
        }
      }
      if (saved != null && saved.elapsedSeconds < 30) {
        saved = null;
      }
    }

    emit(HomeState(
      dailyCompleted: state.dailyCompleted,
      dailyTimeSeconds: state.dailyTimeSeconds,
      dailyDifficulty: state.dailyDifficulty,
      dailyPuzzleNum: state.dailyPuzzleNum,
      currentStreak: state.currentStreak,
      totalSolved: state.totalSolved,
      avgQuality: state.avgQuality,
      insight: state.insight,
      recommendedDifficulty: state.recommendedDifficulty,
      savedGame: saved,
      loaded: state.loaded,
    ));
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _storage.getProfile(),               // 0
        _storage.getAllRecords(),             // 1
        _intelligence.recommendDifficulty(), // 2
        _intelligence.dailyInsight(),        // 3
        _storage.getSavedGame(),             // 4
      ]);

      final profile = results[0] as PlayerProfile;
      final allRecords = results[1] as List<PuzzleRecord>;
      final recommended = results[2] as String;
      final insight = results[3] as String?;
      var saved = results[4] as SavedGame?;

      // Filter out stale/trivial saves
      if (saved != null) {
        // Stale daily from a different day
        if (saved.isDaily) {
          final today = DateTime.now();
          final todayId =
              '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
          if (saved.puzzleId != todayId) {
            await _storage.deleteSavedGame();
            saved = null;
          }
        }
        // Too short to bother resuming
        if (saved != null && saved.elapsedSeconds < 30) {
          await _storage.deleteSavedGame();
          saved = null;
        }
      }

      // Avg quality
      int avgQuality = 0;
      if (allRecords.isNotEmpty) {
        avgQuality =
            (allRecords.map((r) => r.qualityScore).reduce((a, b) => a + b) /
                    allRecords.length)
                .round();
      }

      // Daily puzzle — difficulty rotates by day of week, deterministic
      final today = DateTime.now();
      final dailyDifficulty = SudokuGenerator.dailyDifficulty(today).name;

      // Find today's daily record (single source of truth)
      final todayId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final todayRecord = allRecords.where((r) => r.isDaily && r.puzzleId == todayId).firstOrNull;
      final dailyTime = todayRecord?.timeSeconds;
      final todayCompleted = todayRecord != null;

      // Puzzle number — count of unique daily completions
      final dailyCount = allRecords.where((r) => r.isDaily).length;
      final puzzleNum = todayCompleted ? dailyCount : dailyCount + 1;

      // Update preferred difficulty only if changed
      if (recommended != profile.preferredDifficulty) {
        await _storage.updateProfile(
          PlayerProfilesCompanion(preferredDifficulty: Value(recommended)),
        );
      }

      if (isClosed) return;

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
    // Re-emit current state without savedGame
    emit(HomeState(
      dailyCompleted: state.dailyCompleted,
      dailyTimeSeconds: state.dailyTimeSeconds,
      dailyDifficulty: state.dailyDifficulty,
      dailyPuzzleNum: state.dailyPuzzleNum,
      currentStreak: state.currentStreak,
      totalSolved: state.totalSolved,
      avgQuality: state.avgQuality,
      insight: state.insight,
      recommendedDifficulty: state.recommendedDifficulty,
      savedGame: null,
      loaded: true,
    ));
  }

  @override
  Future<void> close() {
    _savedGameSub?.cancel();
    return super.close();
  }
}

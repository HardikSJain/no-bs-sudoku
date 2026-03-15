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
    this.loaded = false,
  });
}

class HomeCubit extends Cubit<HomeState> {
  final StorageService _storage;
  final IntelligenceEngine _intelligence;

  HomeCubit(this._storage, this._intelligence) : super(const HomeState()) {
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _storage.getProfile(),               // 0
        _storage.getAllRecords(),             // 1
        _storage.hasCompletedDailyToday(),   // 2
        _intelligence.recommendDifficulty(), // 3
        _intelligence.dailyInsight(),        // 4
      ]);

      final profile = results[0] as PlayerProfile;
      final allRecords = results[1] as List<PuzzleRecord>;
      final dailyCompleted = results[2] as bool;
      final recommended = results[3] as String;
      final insight = results[4] as String?;

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

      // Daily puzzle number — count local daily completions + 1
      final dailyCount = allRecords.where((r) => r.isDaily).length;
      final puzzleNum = dailyCount + 1;

      // Check if today's daily was completed
      final todayId =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      int? dailyTime;
      for (final r in allRecords) {
        if (r.isDaily && r.puzzleId == todayId) {
          dailyTime = r.timeSeconds;
          break;
        }
      }

      // Update preferred difficulty only if changed
      if (recommended != profile.preferredDifficulty) {
        await _storage.updateProfile(
          PlayerProfilesCompanion(preferredDifficulty: Value(recommended)),
        );
      }

      if (isClosed) return;

      emit(HomeState(
        dailyCompleted: dailyCompleted || dailyTime != null,
        dailyTimeSeconds: dailyTime,
        dailyDifficulty: dailyDifficulty,
        dailyPuzzleNum: puzzleNum,
        currentStreak: profile.currentStreak,
        totalSolved: profile.totalSolved,
        avgQuality: avgQuality,
        insight: insight,
        recommendedDifficulty: recommended,
        loaded: true,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const HomeState(loaded: true));
    }
  }
}

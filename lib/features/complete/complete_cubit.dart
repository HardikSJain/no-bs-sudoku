import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/velocity_profile.dart';
import '../../core/logger.dart';
import '../../core/storage/storage_service.dart';
import '../../engine/sudoku_solver.dart';

class CompleteState {
  final double qualityScore;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final Difficulty difficulty;
  final bool isDaily;
  final VelocityProfile? velocity;
  final bool isPersonalBest;
  final int currentStreak;
  final List<int> solveTimes;
  /// Seconds faster than the previous personal best. Null if no prior best.
  final int? pbDiffSeconds;
  /// Seconds faster than the user's average. Negative = slower than avg.
  final int? avgDiffSeconds;

  const CompleteState({
    required this.qualityScore,
    required this.timeSeconds,
    required this.hintsUsed,
    required this.mistakes,
    required this.difficulty,
    this.isDaily = false,
    this.velocity,
    this.isPersonalBest = false,
    this.currentStreak = 0,
    this.solveTimes = const [],
    this.pbDiffSeconds,
    this.avgDiffSeconds,
  });
}

class CompleteCubit extends Cubit<CompleteState> {
  CompleteCubit({
    required double qualityScore,
    required int timeSeconds,
    required int hintsUsed,
    required int mistakes,
    required Difficulty difficulty,
    required bool isDaily,
    required List<int> solveTimes,
  }) : super(CompleteState(
          qualityScore: qualityScore,
          timeSeconds: timeSeconds,
          hintsUsed: hintsUsed,
          mistakes: mistakes,
          difficulty: difficulty,
          isDaily: isDaily,
          solveTimes: solveTimes,
        )) {
    _loadContext();
  }

  Future<void> _loadContext() async {
    // Velocity analysis (pure, no DB)
    final velocity = analyzeVelocity(state.solveTimes);

    // Contextual comparison — best-effort, falls back to defaults
    bool isPB = false;
    int streak = 0;
    int? pbDiff;
    int? avgDiff;

    try {
      final storage = StorageService.instance;
      final profile = await storage.getProfile();
      final records = await storage.getRecordsForDifficulty(state.difficulty.name);
      streak = profile.currentStreak;

      if (records.length >= 2) {
        final sorted = [...records]
          ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
        if (sorted.first.timeSeconds == state.timeSeconds) {
          final diff = sorted[1].timeSeconds - state.timeSeconds;
          if (diff > 0) {
            isPB = true;
            pbDiff = diff;
            Log.personalBest(difficulty: state.difficulty.name, timeSeconds: state.timeSeconds);
          }
        }
      }

      if (records.length >= 3) {
        final avgTime = records.map((r) => r.timeSeconds).reduce((a, b) => a + b) / records.length;
        avgDiff = (avgTime - state.timeSeconds).round();
      }
    } catch (_) {
      // Storage read failed — show screen with defaults
    }

    if (isClosed) return;

    emit(CompleteState(
      qualityScore: state.qualityScore,
      timeSeconds: state.timeSeconds,
      hintsUsed: state.hintsUsed,
      mistakes: state.mistakes,
      difficulty: state.difficulty,
      isDaily: state.isDaily,
      velocity: velocity,
      isPersonalBest: isPB,
      currentStreak: streak,
      solveTimes: state.solveTimes,
      pbDiffSeconds: pbDiff,
      avgDiffSeconds: avgDiff,
    ));
  }
}

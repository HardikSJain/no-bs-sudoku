import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/velocity_profile.dart';
import '../../core/storage/storage_service.dart';

class CompleteState {
  final double qualityScore;
  final int timeSeconds;
  final int hintsUsed;
  final int mistakes;
  final String difficulty;
  final bool isDaily;
  final VelocityProfile? velocity;
  final String? comparison;
  final bool isPersonalBest;
  final int currentStreak;
  final List<int> solveTimes;

  const CompleteState({
    required this.qualityScore,
    required this.timeSeconds,
    required this.hintsUsed,
    required this.mistakes,
    required this.difficulty,
    this.isDaily = false,
    this.velocity,
    this.comparison,
    this.isPersonalBest = false,
    this.currentStreak = 0,
    this.solveTimes = const [],
  });
}

class CompleteCubit extends Cubit<CompleteState> {
  CompleteCubit({
    required double qualityScore,
    required int timeSeconds,
    required int hintsUsed,
    required int mistakes,
    required String difficulty,
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
    String? comparison;
    bool isPB = false;
    int streak = 0;

    try {
      final storage = StorageService.instance;
      final profile = await storage.getProfile();
      final records = await storage.getRecordsForDifficulty(state.difficulty);
      streak = profile.currentStreak;

      if (records.length >= 2) {
        final sorted = [...records]
          ..sort((a, b) => a.timeSeconds.compareTo(b.timeSeconds));
        if (sorted.first.timeSeconds == state.timeSeconds) {
          final previousBest = sorted[1].timeSeconds;
          final diff = previousBest - state.timeSeconds;
          if (diff > 0) {
            isPB = true;
            final mins = diff ~/ 60;
            final secs = diff % 60;
            final timeStr = mins > 0 ? '${mins}m ${secs}s' : '${secs}s';
            comparison = 'PB ↑ $timeStr faster than your best';
          }
        }
      }

      if (comparison == null && records.length >= 3) {
        final avgTime =
            records.map((r) => r.timeSeconds).reduce((a, b) => a + b) /
                records.length;
        if (state.timeSeconds < avgTime) {
          final pct = ((1 - state.timeSeconds / avgTime) * 100).round();
          comparison = '−$pct% vs your avg';
        }
      }

      if (comparison == null && records.length == 1) {
        comparison = 'first ${state.difficulty} solve.';
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
      comparison: comparison,
      isPersonalBest: isPB,
      currentStreak: streak,
      solveTimes: state.solveTimes,
    ));
  }
}

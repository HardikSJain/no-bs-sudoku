import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../learn/mastery.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/repositories/repositories.dart';

class StatsState {
  final PlayerProfile? profile;
  final List<PuzzleRecord> allRecords;
  final List<PuzzleRecord> last14Days;
  final Map<String, List<PuzzleRecord>> byDifficulty;
  final List<PuzzleRecord> last10;
  final String? insight;

  /// Null until loaded. Technique mastery is progress too, and the library
  /// is a screen a player may never have found.
  final MasteryProfile? mastery;
  final bool loaded;

  const StatsState({
    this.profile,
    this.allRecords = const [],
    this.last14Days = const [],
    this.byDifficulty = const {},
    this.last10 = const [],
    this.insight,
    this.mastery,
    this.loaded = false,
  });

  int get avgQuality {
    if (allRecords.isEmpty) return 0;
    return (allRecords.map((r) => r.qualityScore).reduce((a, b) => a + b) /
            allRecords.length)
        .round();
  }
}

class StatsCubit extends Cubit<StatsState> {
  final PuzzleRecordRepository _records;
  final ProfileRepository _profiles;
  final IntelligenceEngine _intelligence;
  final MasteryRepository _mastery;

  StatsCubit({
    required PuzzleRecordRepository records,
    required ProfileRepository profiles,
    required IntelligenceEngine intelligence,
    required MasteryRepository mastery,
  })  : _records = records,
        _profiles = profiles,
        _intelligence = intelligence,
        _mastery = mastery,
        super(const StatsState()) {
    load();
  }

  Future<void> load() async {
    try {
      final results = await Future.wait([
        _profiles.getProfile(),
        _records.getAllRecords(),
        _records.getRecentRecords(14),
        _intelligence.dailyInsight(),
        _mastery.getProfile(),
      ]);

      final profile = results[0] as PlayerProfile;
      final allRecords = results[1] as List<PuzzleRecord>;
      final last14 = results[2] as List<PuzzleRecord>;
      final insight = results[3] as String?;

      // Group by difficulty
      final byDiff = <String, List<PuzzleRecord>>{};
      for (final r in allRecords) {
        byDiff.putIfAbsent(r.difficulty, () => []).add(r);
      }

      // Last 10
      final last10 = allRecords.take(10).toList();

      if (isClosed) return;

      emit(StatsState(
        profile: profile,
        allRecords: allRecords,
        last14Days: last14,
        byDifficulty: byDiff,
        last10: last10,
        insight: insight,
        mastery: results[4] as MasteryProfile,
        loaded: true,
      ));
    } catch (_) {
      if (isClosed) return;
      emit(const StatsState(loaded: true));
    }
  }
}

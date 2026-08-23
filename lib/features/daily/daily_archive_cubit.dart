import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/daily_key.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../engine/sudoku_generator.dart';
import '../../engine/sudoku_solver.dart';

/// One day in the archive.
class ArchiveDay {
  const ArchiveDay({
    required this.date,
    required this.difficulty,
    required this.record,
    required this.inProgress,
  });

  final DateTime date;

  /// Known without generating anything: the daily's tier is a function of the
  /// weekday. Ninety puzzles are emphatically not generated to draw a
  /// calendar.
  final Difficulty difficulty;

  /// The finished attempt, if there is one.
  final PuzzleRecord? record;

  /// True when the single saved-game slot is holding this exact daily.
  final bool inProgress;

  bool get isSolved => record != null;
  bool get isToday => date == todayUtc();

  String get id => dailyPuzzleId(date);
}

class DailyArchiveState {
  const DailyArchiveState({
    this.days = const [],
    this.loaded = false,
  });

  /// Oldest first, ending with today.
  final List<ArchiveDay> days;
  final bool loaded;

  int get solvedCount => days.where((d) => d.isSolved).length;

  /// Days that have been and gone without a solve. Today is not one of them
  /// until it is over.
  int get missedCount =>
      days.where((d) => !d.isSolved && !d.isToday).length;
}

class DailyArchiveCubit extends Cubit<DailyArchiveState> {
  DailyArchiveCubit({
    required PuzzleRecordRepository records,
    required SavedGameRepository savedGames,
  })  : _records = records,
        _savedGames = savedGames,
        super(const DailyArchiveState()) {
    load();
  }

  final PuzzleRecordRepository _records;
  final SavedGameRepository _savedGames;

  Future<void> load() async {
    final byDate = await _records.dailyRecordsByDate();
    final saved = (await _savedGames.getSavedGames()).daily;

    final days = [
      for (final date in dailyArchiveDates())
        ArchiveDay(
          date: date,
          difficulty: SudokuGenerator.dailyDifficulty(date),
          record: byDate[dailyPuzzleId(date)],
          inProgress: saved != null &&
              saved.isDaily &&
              saved.puzzleId == dailyPuzzleId(date),
        ),
    ];

    if (isClosed) return;
    emit(DailyArchiveState(days: days, loaded: true));
  }
}

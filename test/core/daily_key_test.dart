import 'package:flutter_test/flutter_test.dart';

import 'package:no_bs_sudoku/core/daily_key.dart';
import 'package:no_bs_sudoku/engine/sudoku_generator.dart';

void main() {
  group('dailyPuzzleId', () {
    test('is derived from UTC, not the local zone', () {
      // This instant is 2026-08-22 01:00 in UTC+05:30 but still 2026-08-21 in
      // UTC. A local-time key would call it the 22nd for a player in India
      // while players elsewhere were on the 21st — two different puzzles for
      // what both call "today". The UTC key gives them the same one.
      final istMidnightPlusOneHour = DateTime.utc(2026, 8, 21, 19, 30);
      expect(dailyPuzzleId(istMidnightPlusOneHour), '2026-08-21');
    });

    test('same instant yields the same id regardless of the offset used', () {
      final instant = DateTime.utc(2026, 8, 22, 3, 0);
      expect(dailyPuzzleId(instant), dailyPuzzleId(instant.toLocal()));
    });

    test('pads month and day', () {
      expect(dailyPuzzleId(DateTime.utc(2026, 1, 5)), '2026-01-05');
    });
  });

  group('todayUtc / dayUtc', () {
    test('todayUtc is midnight UTC', () {
      final t = todayUtc();
      expect(t.isUtc, true);
      expect(t.hour, 0);
      expect(t.minute, 0);
      expect(t.second, 0);
    });

    test('dayUtc buckets a stored timestamp to its UTC day', () {
      expect(
        dayUtc(DateTime.utc(2026, 8, 22, 23, 59)),
        DateTime.utc(2026, 8, 22),
      );
    });

    test('two instants 6 hours apart across UTC midnight bucket differently',
        () {
      // The behaviour change worth knowing: the daily now rolls at UTC
      // midnight, not local midnight.
      expect(
        dayUtc(DateTime.utc(2026, 8, 21, 21, 0)),
        isNot(dayUtc(DateTime.utc(2026, 8, 22, 3, 0))),
      );
    });
  });

  group('daily puzzle is the same for everyone', () {
    test('one UTC date produces one puzzle', () {
      final date = DateTime.utc(2026, 8, 22);
      final a = SudokuGenerator().generateDaily(date: date);
      final b = SudokuGenerator().generateDaily(date: date);
      expect(a.puzzle.toFlatString(), b.puzzle.toFlatString());
      expect(a.difficulty, b.difficulty);
    });
  });
}

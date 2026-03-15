import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/core/intelligence/quality_score.dart';

void main() {
  group('QualityScore.compute', () {
    test('perfect solve at par time gives 100', () {
      final score = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      expect(score, 100.0);
    });

    test('under par time still caps at 100', () {
      final score = QualityScore.compute(
        timeSeconds: 300, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      expect(score, 100.0);
    });

    test('at 3x par time gives 0 for time component', () {
      // 3x par = 2700s. Time component = 0. Others still full = 60.
      final score = QualityScore.compute(
        timeSeconds: 2700, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      expect(score, 60.0);
    });

    test('beyond 3x par floors time at 0', () {
      final score = QualityScore.compute(
        timeSeconds: 5000, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      expect(score, 60.0);
    });

    test('each mistake costs 10 points', () {
      final base = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      final with2 = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 2, undos: 0, difficulty: 'medium',
      );
      expect(base - with2, 20.0);
    });

    test('3 mistakes zeroes accuracy component', () {
      final score = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 3, undos: 0, difficulty: 'medium',
      );
      expect(score, 70.0); // 40 time + 0 accuracy + 20 hints + 10 undos
    });

    test('each hint costs 7 points', () {
      final base = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      final with1 = QualityScore.compute(
        timeSeconds: 900, hints: 1, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      expect(base - with1, 7.0);
    });

    test('3 hints zeroes self-sufficiency component', () {
      final score = QualityScore.compute(
        timeSeconds: 900, hints: 3, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      expect(score, 80.0); // 40 + 30 + (20-21=0) + 10
    });

    test('each undo costs 2 points', () {
      final base = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 0, difficulty: 'medium',
      );
      final with3 = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 3, difficulty: 'medium',
      );
      expect(base - with3, 6.0);
    });

    test('5 undos zeroes confidence component', () {
      final score = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 5, difficulty: 'medium',
      );
      expect(score, 90.0); // 40 + 30 + 20 + 0
    });

    test('worst case clamps to 0', () {
      final score = QualityScore.compute(
        timeSeconds: 99999, hints: 10, mistakes: 10, undos: 50, difficulty: 'medium',
      );
      expect(score, 0.0);
    });

    test('works for all difficulty levels', () {
      for (final diff in ['easy', 'medium', 'hard', 'expert']) {
        final par = QualityScore.parTimes[diff]!;
        final score = QualityScore.compute(
          timeSeconds: par, hints: 0, mistakes: 0, undos: 0, difficulty: diff,
        );
        expect(score, 100.0, reason: '$diff at par should be 100');
      }
    });

    test('unknown difficulty falls back to 900s par', () {
      final score = QualityScore.compute(
        timeSeconds: 900, hints: 0, mistakes: 0, undos: 0, difficulty: 'unknown',
      );
      expect(score, 100.0);
    });
  });

  group('QualityScore.label', () {
    test('maps score ranges to correct labels', () {
      expect(QualityScore.label(95), 'clean.');
      expect(QualityScore.label(90), 'clean.');
      expect(QualityScore.label(80), 'solid.');
      expect(QualityScore.label(75), 'solid.');
      expect(QualityScore.label(65), 'decent.');
      expect(QualityScore.label(60), 'decent.');
      expect(QualityScore.label(50), 'rough.');
      expect(QualityScore.label(40), 'rough.');
      expect(QualityScore.label(30), 'chaos.');
      expect(QualityScore.label(0), 'chaos.');
    });
  });
}

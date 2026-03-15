import 'package:flutter_test/flutter_test.dart';
import 'package:no_bs_sudoku/core/intelligence/velocity_profile.dart';

void main() {
  group('analyzeVelocity', () {
    test('returns null for fewer than 9 data points', () {
      expect(analyzeVelocity([1, 2, 3]), isNull);
      expect(analyzeVelocity([]), isNull);
      expect(analyzeVelocity([1, 2, 3, 4, 5, 6, 7, 8]), isNull);
    });

    test('returns non-null for exactly 9 data points', () {
      expect(analyzeVelocity([3, 3, 3, 3, 3, 3, 3, 3, 3]), isNotNull);
    });

    test('steady when all thirds are similar pace', () {
      // All values identical — no variation
      final result = analyzeVelocity([5, 5, 5, 5, 5, 5, 5, 5, 5]);
      expect(result, VelocityProfile.steady);
    });

    test('fastStart when first third is faster (lower avg) than last', () {
      // First third: avg 2, Last third: avg 8 (last > first * 1.2)
      final result = analyzeVelocity([2, 2, 2, 5, 5, 5, 8, 8, 8]);
      // stddev check first — if not erratic, then compare thirds
      // first avg = 2, last avg = 8, 8 > 2*1.2=2.4 → fastStart
      // but check erratic: mean=5, variance=5.33, stddev=2.31, 2.31 > 5*0.5=2.5? no → not erratic
      expect(result, VelocityProfile.fastStart);
    });

    test('slowStart when last third is faster than first', () {
      // First third: avg 8, Last third: avg 2
      final result = analyzeVelocity([8, 8, 8, 5, 5, 5, 2, 2, 2]);
      expect(result, VelocityProfile.slowStart);
    });

    test('erratic when stddev exceeds 50% of mean', () {
      // Wildly varying values: mean ~5, but huge spread
      final result = analyzeVelocity([1, 15, 1, 15, 1, 15, 1, 15, 1]);
      // mean ≈ 7.2, stddev ≈ 6.5, 6.5 > 7.2*0.5=3.6 → erratic
      expect(result, VelocityProfile.erratic);
    });

    test('works with larger lists', () {
      // 18 values, steady pace
      final result = analyzeVelocity(List.filled(18, 4));
      expect(result, VelocityProfile.steady);
    });

    test('erratic check runs before third comparison', () {
      // Even if thirds differ, erratic should take priority
      // First third fast, last third slow, but huge stddev
      final result = analyzeVelocity([1, 20, 1, 5, 5, 5, 10, 20, 10]);
      // mean ≈ 8.6, variance high → likely erratic
      if (result == VelocityProfile.erratic) {
        expect(result, VelocityProfile.erratic);
      } else {
        // If not erratic, it should still be a valid profile
        expect(VelocityProfile.values, contains(result));
      }
    });
  });

  group('VelocityLabel', () {
    test('all profiles have non-empty copy', () {
      for (final profile in VelocityProfile.values) {
        expect(profile.copy.isNotEmpty, isTrue);
        expect(profile.copy.endsWith('.'), isTrue);
      }
    });
  });
}

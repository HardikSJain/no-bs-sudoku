import 'dart:math';

import '../../engine/sudoku_solver.dart';

class QualityScore {
  /// The formula that produced a score. Stamped on every record so a future
  /// change that genuinely breaks comparability can filter on it.
  ///
  /// Version 2 replaced a hint *count* with weighted hint *depth*. That is
  /// deliberately not such a change — see [compute].
  static const int formulaVersion = 2;

  /// Cost per point of hint depth.
  ///
  /// 7/6, not 1.5. A full reveal is 6 depth, so it costs exactly 7 — the
  /// same as one hint cost under version 1. That is what makes the two
  /// formulas agree at every score version 1 could produce, and it is why
  /// nothing needs to filter old records out.
  ///
  /// 1.5 was calibrated only at the point where both formulas reach zero and
  /// was harsher than version 1 across the whole common range: at one hint it
  /// gave 11 where version 1 gave 13, at two it gave 2 where version 1 gave
  /// 6. Every existing player's average would have quietly dropped.
  static const double _hintDepthWeight = 7 / 6;

  static double compute({
    required int timeSeconds,
    required int hintDepthTotal,
    required int mistakes,
    required int undos,
    required Difficulty difficulty,
  }) {
    final par = difficulty.parSeconds;

    // Time: 40 pts. Full 40 at/under par. Scales to 0 at 3× par.
    final t = (40 * max(0.0, 1 - (timeSeconds - par) / (2.0 * par)))
        .clamp(0.0, 40.0);

    // Accuracy: 30 pts. −10 per mistake. Floor 0.
    final a = max(0.0, 30 - mistakes * 10.0);

    // Self-sufficiency: 20 pts. Floor 0.
    //
    // Weighted by how far each hint was pushed rather than by how many were
    // asked for. A count stopped meaning anything once hints became
    // unlimited — ten would have scored the same as three — and it priced a
    // nudge toward the right box exactly like being handed the digit.
    final h = max(0.0, 20 - hintDepthTotal * _hintDepthWeight);

    // Confidence: 10 pts. −2 per undo. Floor 0.
    final u = max(0.0, 10 - undos * 2.0);

    return (t + a + h + u).clamp(0.0, 100.0);
  }

  static String label(double score) {
    if (score >= 90) return 'clean.';
    if (score >= 75) return 'solid.';
    if (score >= 60) return 'decent.';
    if (score >= 40) return 'rough.';
    return 'chaos.';
  }
}

import 'dart:math';

class QualityScore {
  static const parTimes = {
    'easy': 600,
    'medium': 900,
    'hard': 1200,
    'expert': 1800,
  };

  static double compute({
    required int timeSeconds,
    required int hints,
    required int mistakes,
    required int undos,
    required String difficulty,
  }) {
    final par = parTimes[difficulty] ?? 900;

    // Time: 40 pts. Full 40 at/under par. Scales to 0 at 3× par.
    final t = (40 * max(0.0, 1 - (timeSeconds - par) / (2.0 * par)))
        .clamp(0.0, 40.0);

    // Accuracy: 30 pts. −10 per mistake. Floor 0.
    final a = max(0.0, 30 - mistakes * 10.0);

    // Self-sufficiency: 20 pts. −7 per hint. Floor 0.
    final h = max(0.0, 20 - hints * 7.0);

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

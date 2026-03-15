import 'dart:math';

enum VelocityProfile { fastStart, slowStart, steady, erratic }

extension VelocityLabel on VelocityProfile {
  String get copy => switch (this) {
        VelocityProfile.fastStart => 'strong opener.',
        VelocityProfile.slowStart => 'warmed up towards the end.',
        VelocityProfile.steady => 'consistent pace.',
        VelocityProfile.erratic => 'thinking in bursts.',
      };
}

/// Analyzes solve velocity from a list of time deltas between placements.
/// Returns null if fewer than 9 data points.
VelocityProfile? analyzeVelocity(List<int> solveTimes) {
  if (solveTimes.length < 9) return null;

  final third = solveTimes.length ~/ 3;
  final first = solveTimes.sublist(0, third);
  final last = solveTimes.sublist(solveTimes.length - third);

  final firstAvg = first.reduce((a, b) => a + b) / first.length;
  final lastAvg = last.reduce((a, b) => a + b) / last.length;

  // Check erratic: stddev > 50% of mean
  final mean = solveTimes.reduce((a, b) => a + b) / solveTimes.length;
  if (mean > 0) {
    final variance =
        solveTimes.map((t) => (t - mean) * (t - mean)).reduce((a, b) => a + b) /
            solveTimes.length;
    final stddev = sqrt(variance);
    if (stddev > mean * 0.5) return VelocityProfile.erratic;
  }

  // Compare thirds
  if (firstAvg > 0 && lastAvg > firstAvg * 1.2) {
    return VelocityProfile.fastStart;
  }
  if (lastAvg > 0 && firstAvg > lastAvg * 1.2) {
    return VelocityProfile.slowStart;
  }

  return VelocityProfile.steady;
}

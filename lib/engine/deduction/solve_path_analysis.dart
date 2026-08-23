import 'deduction.dart';
import 'deduction_engine.dart';

/// One technique's contribution to a solve.
class TechniqueUse {
  const TechniqueUse({
    required this.technique,
    required this.count,
    required this.firstStep,
  });

  final Technique technique;

  /// How many steps used it.
  final int count;

  /// The zero-based index of the first step that did, so the UI can say
  /// *when* the puzzle got hard rather than only that it did.
  final int firstStep;
}

/// The shape of a solve: what it took, and where the work actually was.
class SolvePathAnalysis {
  const SolvePathAnalysis({
    required this.totalSteps,
    required this.uses,
    required this.tierByStep,
    required this.hardest,
    required this.complete,
  });

  /// Reads a finished path. Cheap — the ladder has already run.
  factory SolvePathAnalysis.of(SolvePath path) {
    final counts = <Technique, int>{};
    final first = <Technique, int>{};
    for (int i = 0; i < path.steps.length; i++) {
      final t = path.steps[i].technique;
      counts[t] = (counts[t] ?? 0) + 1;
      first.putIfAbsent(t, () => i);
    }

    final uses = [
      for (final entry in counts.entries)
        TechniqueUse(
          technique: entry.key,
          count: entry.value,
          firstStep: first[entry.key]!,
        ),
    ]..sort((a, b) {
        // Hardest first: this is the part a reader is looking for.
        final byTier = b.technique.rank.compareTo(a.technique.rank);
        return byTier != 0 ? byTier : a.firstStep.compareTo(b.firstStep);
      });

    return SolvePathAnalysis(
      totalSteps: path.steps.length,
      uses: uses,
      tierByStep: [for (final s in path.steps) s.technique.tier],
      hardest: path.hardestTechnique,
      complete: path.complete,
    );
  }

  final int totalSteps;

  /// Every technique the solve needed, hardest first.
  final List<TechniqueUse> uses;

  /// The tier of each step in order — the solve's profile over time, which is
  /// what makes "it was easy until step 40" visible at a glance.
  final List<TechniqueTier> tierByStep;

  final Technique? hardest;

  final bool complete;

  /// How far into the solve the hardest technique first appeared, 0..1.
  ///
  /// Null when there is nothing to place it against.
  double? get hardestAt {
    if (hardest == null || totalSteps == 0) return null;
    final use = uses.firstWhere((u) => u.technique == hardest);
    return use.firstStep / totalSteps;
  }

  /// The number of steps that were nothing but singles.
  int get routineSteps => tierByStep
      .where((t) => t == TechniqueTier.singles)
      .length;
}

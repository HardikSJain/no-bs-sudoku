import '../sudoku_board.dart';
import 'candidate_grid.dart';
import 'deduction.dart';
import 'rules/chains.dart';
import 'rules/fish.dart';
import 'rules/intersections.dart';
import 'rules/singles.dart';
import 'rules/subsets.dart';
import 'technique_rule.dart';

/// The result of solving by logic alone.
class SolvePath {
  const SolvePath({
    required this.steps,
    required this.complete,
    required this.hardestTechnique,
    required this.board,
  });

  final List<Deduction> steps;

  /// The grid after every step was applied. Generation compares this against
  /// the ground-truth solution — a complete path that lands somewhere else
  /// would mean an unsound rule, which bare uniqueness checking cannot catch.
  final SudokuBoard board;

  /// True when the grid was filled without ever guessing. False means the
  /// ladder ran out of techniques, or the grid was already contradictory.
  final bool complete;

  /// The hardest step the solve actually needed — null for an empty path.
  final Technique? hardestTechnique;

  /// The tier a puzzle needs, which is what difficulty labels are built from.
  TechniqueTier? get hardestTier => hardestTechnique?.tier;

  int get stepCount => steps.length;
}

/// Runs the technique ladder.
///
/// Rules are tried easiest-first and the first hit wins, so a hint never
/// explains an x-wing when a naked single was sitting there. That ordering is
/// the whole reason the ladder exists — it is what makes an explanation the
/// *simplest* available reason rather than merely a true one.
class DeductionEngine {
  const DeductionEngine([List<TechniqueRule>? rules]) : _rules = rules ?? _ladder;

  final List<TechniqueRule> _rules;

  static const List<TechniqueRule> _ladder = [
    NakedSingleRule(),
    HiddenSingleRule(),
    NakedSubsetRule.pair(),
    HiddenSubsetRule.pair(),
    NakedSubsetRule.triple(),
    HiddenSubsetRule.triple(),
    PointingPairRule(),
    BoxLineReductionRule(),
    BasicFishRule.xWing(),
    BasicFishRule.swordfish(),
    XyWingRule(),
    SimpleColoringRule(),
  ];

  /// Every technique the engine knows, easiest first.
  List<Technique> get techniques => [for (final r in _rules) r.technique];

  /// The simplest single step available, or null when nothing applies.
  ///
  /// Powers hints and stuck detection.
  Deduction? nextStep(
    CandidateGrid grid, {
    TechniqueTier maxTier = TechniqueTier.chains,
  }) {
    if (grid.isBroken) return null;
    for (final rule in _rules) {
      if (rule.tier.index > maxTier.index) continue;
      final found = rule.find(grid);
      if (found != null) return found;
    }
    return null;
  }

  /// Every step available right now, across all permitted rules.
  ///
  /// One per rule — each rule reports its first find. Used by attribution to
  /// ask "which techniques *could* have explained this move", which is a
  /// different question from "what should we show".
  List<Deduction> allStepsAt(
    CandidateGrid grid, {
    TechniqueTier maxTier = TechniqueTier.chains,
  }) {
    if (grid.isBroken) return const [];
    return [
      for (final rule in _rules)
        if (rule.tier.index <= maxTier.index) ?rule.find(grid),
    ];
  }

  /// Solves as far as logic takes it, recording every step.
  ///
  /// Never guesses. A puzzle that needs a guess comes back with
  /// `complete: false`, which is exactly the signal generation uses to reject
  /// it.
  SolvePath solve(
    CandidateGrid grid, {
    TechniqueTier maxTier = TechniqueTier.chains,
  }) {
    final work = grid.clone();
    final steps = <Deduction>[];
    Technique? hardest;

    while (!work.isSolved) {
      final step = nextStep(work, maxTier: maxTier);
      if (step == null) break;
      steps.add(step);
      if (hardest == null || step.technique.index > hardest.index) {
        hardest = step.technique;
      }
      apply(work, step);
      if (work.isBroken) break;
    }

    return SolvePath(
      steps: steps,
      complete: work.isSolved,
      hardestTechnique: hardest,
      board: work.toBoard(),
    );
  }

  /// Writes a deduction into the grid.
  static void apply(CandidateGrid grid, Deduction step) {
    switch (step.kind) {
      case DeductionKind.placement:
        for (final (idx, digit) in step.targets) {
          grid.place(idx, digit);
        }
      case DeductionKind.elimination:
        for (final (idx, digit) in step.targets) {
          grid.eliminate(idx, digit);
        }
    }
  }
}

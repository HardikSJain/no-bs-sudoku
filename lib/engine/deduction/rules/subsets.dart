import '../candidate_grid.dart';
import '../deduction.dart';
import '../technique_rule.dart';
import '../units.dart';

/// k cells in a unit that between them hold exactly k digits.
///
/// Those k digits are used up by those k cells whatever the order, so no
/// other cell in the unit can have them.
class NakedSubsetRule implements TechniqueRule {
  const NakedSubsetRule.pair() : size = 2, technique = Technique.nakedPair;
  const NakedSubsetRule.triple() : size = 3, technique = Technique.nakedTriple;

  final int size;

  @override
  final Technique technique;

  @override
  TechniqueTier get tier => TechniqueTier.pairs;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int unitId = 0; unitId < Units.unitCount; unitId++) {
      final open = [
        for (final idx in Units.unitCells[unitId])
          if (!grid.isPlaced(idx)) idx,
      ];
      // With only k open cells the "subset" is the whole unit and eliminates
      // nothing.
      if (open.length <= size) continue;

      for (final combo in combinations(open, size)) {
        int mask = 0;
        for (final idx in combo) {
          mask |= grid.candidateMask(idx);
        }
        if (Units.popCount(mask) != size) continue;

        final digits = Units.digitsIn(mask);
        final targets = <(int, int)>[];
        for (final idx in open) {
          if (combo.contains(idx)) continue;
          for (final digit in digits) {
            if (grid.hasCandidate(idx, digit)) targets.add((idx, digit));
          }
        }
        if (targets.isEmpty) continue;

        return Deduction(
          technique: technique,
          kind: DeductionKind.elimination,
          targets: targets,
          witnesses: combo,
          unit: UnitRef.fromId(unitId),
        );
      }
    }
    return null;
  }
}

/// k digits in a unit that between them can only go in k cells.
///
/// Those cells are spoken for, so every other candidate in them goes.
class HiddenSubsetRule implements TechniqueRule {
  const HiddenSubsetRule.pair() : size = 2, technique = Technique.hiddenPair;
  const HiddenSubsetRule.triple()
      : size = 3,
        technique = Technique.hiddenTriple;

  final int size;

  @override
  final Technique technique;

  @override
  TechniqueTier get tier => TechniqueTier.pairs;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int unitId = 0; unitId < Units.unitCount; unitId++) {
      // Digits still to be placed here, and where they could go.
      final spots = <int, List<int>>{};
      for (int digit = 1; digit <= 9; digit++) {
        final cells = grid.cellsWithCandidate(unitId, digit);
        // A digit with one spot is a hidden single — a cheaper rule's job.
        if (cells.length >= 2 && cells.length <= size) spots[digit] = cells;
      }
      if (spots.length < size) continue;

      for (final combo in combinations(spots.keys.toList(), size)) {
        final cover = <int>{for (final digit in combo) ...spots[digit]!};
        if (cover.length != size) continue;

        int keep = 0;
        for (final digit in combo) {
          keep |= Units.maskOf(digit);
        }

        final targets = <(int, int)>[];
        for (final idx in cover) {
          for (final digit in Units.digitsIn(grid.candidateMask(idx) & ~keep)) {
            targets.add((idx, digit));
          }
        }
        if (targets.isEmpty) continue;

        return Deduction(
          technique: technique,
          kind: DeductionKind.elimination,
          targets: targets,
          witnesses: cover.toList(),
          unit: UnitRef.fromId(unitId),
        );
      }
    }
    return null;
  }
}

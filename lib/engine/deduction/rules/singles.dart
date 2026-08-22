import '../candidate_grid.dart';
import '../deduction.dart';
import '../technique_rule.dart';
import '../units.dart';

/// One cell, one possibility left.
class NakedSingleRule implements TechniqueRule {
  const NakedSingleRule();

  @override
  Technique get technique => Technique.nakedSingle;

  @override
  TechniqueTier get tier => TechniqueTier.singles;

  @override
  Deduction? find(CandidateGrid grid) {
    for (final idx in grid.unsolvedCells) {
      if (grid.candidateCount(idx) != 1) continue;
      final digit = grid.candidatesOf(idx).first;
      return Deduction(
        technique: technique,
        kind: DeductionKind.placement,
        targets: [(idx, digit)],
        // The proof is the filled peers — between them they rule out the
        // other eight digits.
        witnesses: [
          for (final peer in Units.peersOf[idx])
            if (grid.isPlaced(peer)) peer,
        ],
      );
    }
    return null;
  }
}

/// One digit, one place left in a unit — even though that cell still has
/// other candidates of its own.
class HiddenSingleRule implements TechniqueRule {
  const HiddenSingleRule();

  @override
  Technique get technique => Technique.hiddenSingle;

  @override
  TechniqueTier get tier => TechniqueTier.singles;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int unitId = 0; unitId < Units.unitCount; unitId++) {
      final cells = Units.unitCells[unitId];
      for (int digit = 1; digit <= 9; digit++) {
        // Already settled in this unit.
        if (cells.any((idx) => grid.placed(idx) == digit)) continue;
        final spots = grid.cellsWithCandidate(unitId, digit);
        if (spots.length != 1) continue;
        final target = spots.first;
        // A naked single is the same placement by an easier argument; leave
        // it to the cheaper rule so hints stay at the lowest tier that works.
        if (grid.candidateCount(target) == 1) continue;
        return Deduction(
          technique: technique,
          kind: DeductionKind.placement,
          targets: [(target, digit)],
          // The proof is the placed digits elsewhere that block every other
          // cell of this unit.
          witnesses: _blockers(grid, cells, target, digit),
          unit: UnitRef.fromId(unitId),
        );
      }
    }
    return null;
  }

  /// Placed cells holding [digit] that see some cell of [cells] other than
  /// [target] — between them, they are why nowhere else works.
  List<int> _blockers(
    CandidateGrid grid,
    List<int> cells,
    int target,
    int digit,
  ) {
    final blockers = <int>{};
    for (final idx in cells) {
      if (idx == target || grid.isPlaced(idx)) continue;
      for (final peer in Units.peersOf[idx]) {
        if (grid.placed(peer) == digit) blockers.add(peer);
      }
    }
    return blockers.toList();
  }
}

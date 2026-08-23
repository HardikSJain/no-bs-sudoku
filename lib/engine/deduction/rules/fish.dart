import '../candidate_grid.dart';
import '../deduction.dart';
import '../technique_rule.dart';
import '../units.dart';

/// X-wing (2), swordfish (3) and jellyfish (4).
///
/// Pick n rows in which a digit has spots in only n columns between them.
/// Whichever way it falls, those n rows use up all n columns, so the digit
/// cannot appear in those columns anywhere else. Then the same argument with
/// rows and columns swapped.
class BasicFishRule implements TechniqueRule {
  const BasicFishRule.xWing() : size = 2, technique = Technique.xWing;
  const BasicFishRule.swordfish() : size = 3, technique = Technique.swordfish;
  const BasicFishRule.jellyfish() : size = 4, technique = Technique.jellyfish;

  final int size;

  @override
  final Technique technique;

  @override
  TechniqueTier get tier => TechniqueTier.fish;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int digit = 1; digit <= 9; digit++) {
      // byRow: base units are rows, eliminations happen down columns.
      final found = _search(grid, digit, byRow: true) ??
          _search(grid, digit, byRow: false);
      if (found != null) return found;
    }
    return null;
  }

  Deduction? _search(CandidateGrid grid, int digit, {required bool byRow}) {
    // Base units hold the pattern; cover units are where we eliminate.
    final baseOffset = byRow ? 0 : 9;
    final coverOffset = byRow ? 9 : 0;

    // Base lines where the digit has 2..size spots. Fewer than 2 means it is
    // placed or a hidden single — not a fish.
    final candidates = <int, List<int>>{};
    for (int line = 0; line < 9; line++) {
      final spots = grid.cellsWithCandidate(baseOffset + line, digit);
      if (spots.length >= 2 && spots.length <= size) {
        candidates[line] = spots;
      }
    }
    if (candidates.length < size) return null;

    for (final combo in combinations(candidates.keys.toList(), size)) {
      final witnesses = <int>[];
      final cross = <int>{};
      for (final line in combo) {
        for (final idx in candidates[line]!) {
          witnesses.add(idx);
          cross.add(byRow ? Units.colOf[idx] : Units.rowOf[idx]);
        }
      }
      if (cross.length != size) continue;

      final targets = <(int, int)>[
        for (final c in cross)
          for (final idx in Units.unitCells[coverOffset + c])
            if (!witnesses.contains(idx) && grid.hasCandidate(idx, digit))
              (idx, digit),
      ];
      if (targets.isEmpty) continue;

      return Deduction(
        technique: technique,
        kind: DeductionKind.elimination,
        targets: targets,
        witnesses: witnesses,
      );
    }
    return null;
  }
}

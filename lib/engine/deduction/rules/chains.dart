import '../candidate_grid.dart';
import '../deduction.dart';
import '../technique_rule.dart';
import '../units.dart';

/// Three cells, two candidates each: a pivot {x,y} with one pincer {x,z} and
/// another {y,z}, both seeing the pivot.
///
/// The pivot is x or y, so one pincer or the other is forced to z. Either
/// way, anything that sees both pincers cannot be z.
class XyWingRule implements TechniqueRule {
  const XyWingRule();

  @override
  Technique get technique => Technique.xyWing;

  @override
  TechniqueTier get tier => TechniqueTier.chains;

  @override
  Deduction? find(CandidateGrid grid) {
    final bivalue = [
      for (final idx in grid.unsolvedCells)
        if (grid.candidateCount(idx) == 2) idx,
    ];

    for (final pivot in bivalue) {
      final pv = grid.candidatesOf(pivot).toList();
      final x = pv[0];
      final y = pv[1];

      final seen = [
        for (final idx in Units.peersOf[pivot])
          if (bivalue.contains(idx)) idx,
      ];

      for (final a in seen) {
        final am = grid.candidateMask(a);
        // Pincer A must be {x, z} — carries x, not y.
        if (am & Units.maskOf(x) == 0 || am & Units.maskOf(y) != 0) continue;
        final z = Units.digitsIn(am & ~Units.maskOf(x)).first;

        for (final b in seen) {
          if (b == a) continue;
          // Pincer B must be exactly {y, z}.
          if (grid.candidateMask(b) !=
              (Units.maskOf(y) | Units.maskOf(z))) {
            continue;
          }

          final targets = <(int, int)>[
            for (final idx in Units.peersOf[a])
              if (idx != pivot &&
                  idx != b &&
                  Units.peersOf[b].contains(idx) &&
                  grid.hasCandidate(idx, z))
                (idx, z),
          ];
          if (targets.isEmpty) continue;

          return Deduction(
            technique: technique,
            kind: DeductionKind.elimination,
            targets: targets,
            witnesses: [pivot, a, b],
          );
        }
      }
    }
    return null;
  }
}

/// Follow a digit through the units where it has exactly two homes.
///
/// Those two cells are a conjugate pair: exactly one of them is the digit.
/// Chaining pairs together two-colours a cluster, and one colour is entirely
/// true while the other is entirely false. Two conclusions follow:
///
/// - if one colour appears twice in a unit, that colour is false outright, so
///   the digit goes from every cell wearing it;
/// - any cell outside the cluster that sees both colours cannot be the digit,
///   because one of the two colours is true.
class SimpleColoringRule implements TechniqueRule {
  const SimpleColoringRule();

  @override
  Technique get technique => Technique.simpleColoring;

  @override
  TechniqueTier get tier => TechniqueTier.chains;

  @override
  Deduction? find(CandidateGrid grid) {
    for (int digit = 1; digit <= 9; digit++) {
      final links = _conjugateLinks(grid, digit);
      if (links.isEmpty) continue;

      final colour = <int, int>{};
      for (final start in links.keys) {
        if (colour.containsKey(start)) continue;
        final cluster = _twoColour(links, start, colour);
        if (cluster.length < 4) continue;

        final found = _contradiction(cluster, colour, digit) ??
            _seesBothColours(grid, cluster, colour, digit);
        if (found != null) return found;
      }
    }
    return null;
  }

  /// Cells joined when a unit has exactly two homes left for the digit.
  Map<int, Set<int>> _conjugateLinks(CandidateGrid grid, int digit) {
    final links = <int, Set<int>>{};
    for (int unitId = 0; unitId < Units.unitCount; unitId++) {
      final spots = grid.cellsWithCandidate(unitId, digit);
      if (spots.length != 2) continue;
      links.putIfAbsent(spots[0], () => <int>{}).add(spots[1]);
      links.putIfAbsent(spots[1], () => <int>{}).add(spots[0]);
    }
    return links;
  }

  /// Breadth-first alternate colouring from [start]. Writes into [colour] and
  /// returns the cells reached.
  List<int> _twoColour(
    Map<int, Set<int>> links,
    int start,
    Map<int, int> colour,
  ) {
    final cluster = <int>[start];
    colour[start] = 0;
    final queue = <int>[start];
    while (queue.isNotEmpty) {
      final cell = queue.removeAt(0);
      for (final next in links[cell]!) {
        if (colour.containsKey(next)) continue;
        colour[next] = 1 - colour[cell]!;
        cluster.add(next);
        queue.add(next);
      }
    }
    return cluster;
  }

  /// One colour twice in a unit — that colour is false everywhere.
  Deduction? _contradiction(
    List<int> cluster,
    Map<int, int> colour,
    int digit,
  ) {
    for (int i = 0; i < cluster.length; i++) {
      for (int j = i + 1; j < cluster.length; j++) {
        final a = cluster[i];
        final b = cluster[j];
        if (colour[a] != colour[b]) continue;
        if (!Units.peersOf[a].contains(b)) continue;

        final doomed = colour[a]!;
        return Deduction(
          technique: Technique.simpleColoring,
          kind: DeductionKind.elimination,
          targets: [
            for (final idx in cluster)
              if (colour[idx] == doomed) (idx, digit),
          ],
          witnesses: [a, b],
        );
      }
    }
    return null;
  }

  /// A cell outside the cluster seeing both colours cannot hold the digit.
  Deduction? _seesBothColours(
    CandidateGrid grid,
    List<int> cluster,
    Map<int, int> colour,
    int digit,
  ) {
    final zero = [for (final idx in cluster) if (colour[idx] == 0) idx];
    final one = [for (final idx in cluster) if (colour[idx] == 1) idx];
    if (zero.isEmpty || one.isEmpty) return null;

    final targets = <(int, int)>[];
    final witnesses = <int>{};
    for (final idx in grid.unsolvedCells) {
      if (cluster.contains(idx)) continue;
      if (!grid.hasCandidate(idx, digit)) continue;
      final peers = Units.peersOf[idx];
      final a = zero.where(peers.contains).firstOrNull;
      final b = one.where(peers.contains).firstOrNull;
      if (a == null || b == null) continue;
      targets.add((idx, digit));
      witnesses..add(a)..add(b);
    }
    if (targets.isEmpty) return null;

    return Deduction(
      technique: Technique.simpleColoring,
      kind: DeductionKind.elimination,
      targets: targets,
      witnesses: witnesses.toList(),
    );
  }
}

import 'candidate_grid.dart';
import 'deduction.dart';

/// One technique, able to spot itself in a grid.
///
/// A rule returns the *first* deduction it finds and never mutates the grid —
/// applying a step is the engine's job, so the same rule can be used to hint
/// (find, then stop) and to solve (find, apply, repeat).
///
/// A rule must return null rather than a deduction that changes nothing: the
/// engine treats a non-null result as progress, and a no-op step would spin
/// the solve loop forever.
abstract interface class TechniqueRule {
  Technique get technique;

  TechniqueTier get tier;

  Deduction? find(CandidateGrid grid);
}

/// Every k-sized combination of [items], in order. Used by the subset and
/// fish rules, where "pick 2 of these 9" is the search.
Iterable<List<T>> combinations<T>(List<T> items, int k) sync* {
  if (k <= 0 || k > items.length) return;
  final idx = List<int>.generate(k, (i) => i);
  while (true) {
    yield [for (final i in idx) items[i]];
    int pos = k - 1;
    while (pos >= 0 && idx[pos] == items.length - k + pos) {
      pos--;
    }
    if (pos < 0) return;
    idx[pos]++;
    for (int i = pos + 1; i < k; i++) {
      idx[i] = idx[i - 1] + 1;
    }
  }
}

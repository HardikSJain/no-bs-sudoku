import 'dart:typed_data';

import '../sudoku_board.dart';
import 'units.dart';

/// The solver's working state: what each cell holds, and what it could hold.
///
/// Deliberately separate from [SudokuBoard], which is a value type with
/// `==`/`hashCode` over all 81 cells and is used as a `copyWith` identity by
/// the grid widget. Hanging mutable elimination state off it would break both
/// of those.
///
/// Candidates are nine-bit masks (bit 0 is digit 1) so a rule can intersect
/// and difference whole cells with one instruction — the ladder does that
/// tens of thousands of times per generated puzzle.
class CandidateGrid {
  CandidateGrid._(this._candidates, this._placed);

  /// Builds from a board and runs elimination to a fixed point, so the result
  /// is immediately consistent — every placed digit is already gone from its
  /// peers.
  factory CandidateGrid.fromBoard(SudokuBoard board) {
    final grid = CandidateGrid._(
      Uint16List(Units.cellCount)..fillRange(0, Units.cellCount, Units.allDigits),
      Uint8List(Units.cellCount),
    );
    for (int i = 0; i < Units.cellCount; i++) {
      final digit = board.get(i ~/ 9, i % 9);
      if (digit != 0) grid.place(i, digit);
    }
    return grid;
  }

  /// Builds from a board plus an explicit candidate state.
  ///
  /// [CandidateGrid.fromBoard] derives candidates from the placed digits
  /// alone, which is right for an ordinary puzzle and wrong wherever
  /// eliminations have already happened. An elimination leaves no mark on the
  /// board — that is what makes it an elimination — so a position reached by
  /// eliminating carries information the board cannot hold. Rebuilding from
  /// the board there silently restores candidates that were ruled out, and
  /// the engine then answers a question about a position nobody is looking
  /// at.
  ///
  /// Cells absent from [notes] fall back to the derived candidates, so a
  /// partially noted grid behaves sensibly.
  factory CandidateGrid.fromBoardAndNotes(
    SudokuBoard board,
    Map<int, Set<int>> notes,
  ) {
    final grid = CandidateGrid.fromBoard(board);
    for (final entry in notes.entries) {
      if (grid.isPlaced(entry.key)) continue;
      for (int d = 1; d <= 9; d++) {
        if (!entry.value.contains(d)) grid.eliminate(entry.key, d);
      }
    }
    return grid;
  }

  final Uint16List _candidates;
  final Uint8List _placed;

  int candidateMask(int idx) => _candidates[idx];

  Iterable<int> candidatesOf(int idx) => Units.digitsIn(_candidates[idx]);

  int candidateCount(int idx) => Units.popCount(_candidates[idx]);

  bool hasCandidate(int idx, int digit) =>
      _candidates[idx] & Units.maskOf(digit) != 0;

  /// 0 when the cell is still empty.
  int placed(int idx) => _placed[idx];

  bool isPlaced(int idx) => _placed[idx] != 0;

  /// Returns true only when the candidate was actually there — rules use the
  /// return value to decide whether they made progress, so a no-op must
  /// report false.
  bool eliminate(int idx, int digit) {
    final mask = Units.maskOf(digit);
    if (_candidates[idx] & mask == 0) return false;
    _candidates[idx] &= ~mask;
    return true;
  }

  /// Sets the digit, clears the cell's own candidates, and removes the digit
  /// from every peer.
  void place(int idx, int digit) {
    _placed[idx] = digit;
    _candidates[idx] = 0;
    final mask = ~Units.maskOf(digit);
    for (final peer in Units.peersOf[idx]) {
      _candidates[peer] &= mask;
    }
  }

  bool get isSolved {
    for (int i = 0; i < Units.cellCount; i++) {
      if (_placed[i] == 0) return false;
    }
    return true;
  }

  /// An empty cell with nowhere left to go. The ladder stops here rather than
  /// looping: no rule can make progress on a contradiction.
  bool get isBroken {
    for (int i = 0; i < Units.cellCount; i++) {
      if (_placed[i] == 0 && _candidates[i] == 0) return true;
    }
    return false;
  }

  /// Cells still to be filled, ascending.
  Iterable<int> get unsolvedCells sync* {
    for (int i = 0; i < Units.cellCount; i++) {
      if (_placed[i] == 0) yield i;
    }
  }

  /// The cells in [unitId] that still list [digit] as a candidate.
  List<int> cellsWithCandidate(int unitId, int digit) {
    final mask = Units.maskOf(digit);
    return [
      for (final idx in Units.unitCells[unitId])
        if (_candidates[idx] & mask != 0) idx,
    ];
  }

  CandidateGrid clone() => CandidateGrid._(
        Uint16List.fromList(_candidates),
        Uint8List.fromList(_placed),
      );

  SudokuBoard toBoard() => SudokuBoard(List<int>.from(_placed));
}

/// Represents a 9x9 Sudoku board as a flat list of 81 integers.
/// 0 means empty. Values 1-9 are valid digits.
class SudokuBoard {
  final List<int> _cells;

  SudokuBoard(List<int> cells) : _cells = List<int>.from(cells) {
    if (_cells.length != 81) {
      throw ArgumentError('Board must have exactly 81 cells, got ${_cells.length}');
    }
    for (int i = 0; i < 81; i++) {
      if (_cells[i] < 0 || _cells[i] > 9) {
        throw ArgumentError('Cell $i has invalid value ${_cells[i]}, must be 0-9');
      }
    }
  }

  SudokuBoard.empty() : _cells = List<int>.filled(81, 0);

  SudokuBoard copy() => SudokuBoard(_cells);

  int get(int row, int col) => _cells[row * 9 + col];

  void set(int row, int col, int value) {
    _cells[row * 9 + col] = value;
  }

  /// Returns all values in the given row.
  List<int> row(int r) => List.generate(9, (c) => get(r, c));

  /// Returns all values in the given column.
  List<int> col(int c) => List.generate(9, (r) => get(r, c));

  /// Returns all values in the 3x3 box containing (row, col).
  List<int> box(int row, int col) {
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    return [
      for (int r = br; r < br + 3; r++)
        for (int c = bc; c < bc + 3; c++) get(r, c),
    ];
  }

  /// Returns the set of candidates (possible values) for a cell.
  Set<int> candidates(int row, int col) {
    if (get(row, col) != 0) return {};
    final used = <int>{
      ...this.row(row).where((v) => v != 0),
      ...this.col(col).where((v) => v != 0),
      ...box(row, col).where((v) => v != 0),
    };
    return {for (int v = 1; v <= 9; v++) if (!used.contains(v)) v};
  }

  /// Returns true if placing [value] at (row, col) doesn't violate constraints.
  bool isValid(int row, int col, int value) {
    // Check row
    for (int c = 0; c < 9; c++) {
      if (c != col && get(row, c) == value) return false;
    }
    // Check column
    for (int r = 0; r < 9; r++) {
      if (r != row && get(r, col) == value) return false;
    }
    // Check box
    final br = (row ~/ 3) * 3;
    final bc = (col ~/ 3) * 3;
    for (int r = br; r < br + 3; r++) {
      for (int c = bc; c < bc + 3; c++) {
        if (r != row && c != col && get(r, c) == value) return false;
      }
    }
    return true;
  }

  /// Count of non-zero cells.
  int get clueCount => _cells.where((v) => v != 0).length;

  /// Returns true if the board is completely and correctly filled.
  bool get isSolved {
    for (int r = 0; r < 9; r++) {
      for (int c = 0; c < 9; c++) {
        final v = get(r, c);
        if (v == 0) return false;
        if (!isValid(r, c, v)) return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (other is! SudokuBoard) return false;
    for (int i = 0; i < 81; i++) {
      if (_cells[i] != other._cells[i]) return false;
    }
    return true;
  }

  @override
  int get hashCode => Object.hashAll(_cells);

  /// Comma-separated flat string of all 81 cells (for storage).
  String toFlatString() => _cells.join(',');

  /// Reconstruct from a comma-separated flat string.
  factory SudokuBoard.fromFlatString(String s) =>
      SudokuBoard(s.split(',').map(int.parse).toList());

  @override
  String toString() {
    final buf = StringBuffer();
    for (int r = 0; r < 9; r++) {
      if (r > 0 && r % 3 == 0) buf.writeln('------+-------+------');
      for (int c = 0; c < 9; c++) {
        if (c > 0 && c % 3 == 0) buf.write(' | ');
        else if (c > 0) buf.write(' ');
        final v = get(r, c);
        buf.write(v == 0 ? '.' : '$v');
      }
      buf.writeln();
    }
    return buf.toString();
  }
}

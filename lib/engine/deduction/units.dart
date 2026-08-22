/// Precomputed sudoku geometry.
///
/// The ladder runs thousands of times per generated puzzle, and every rule
/// asks the same three questions of a cell: which row, column and box is it
/// in, and which cells does it see. Recomputing that per query is the
/// dominant avoidable cost, so it is all built once at class-load time.
///
/// A "unit" is any of the 27 groups that must contain each digit exactly
/// once: 9 rows, then 9 columns, then 9 boxes, in that order. A unit id is an
/// index into [unitCells], so `unitId < 9` is a row, `< 18` a column, and the
/// rest boxes — [unitKindOf] does that arithmetic by name.
library;

enum UnitKind { row, column, box }

/// Identifies one of the 27 units. Value type — deductions carry it, and
/// deductions compare by value.
class UnitRef {
  const UnitRef(this.kind, this.index);

  /// The unit id used by [Units.unitCells].
  factory UnitRef.fromId(int unitId) => UnitRef(
        Units.unitKindOf(unitId),
        unitId % 9,
      );

  final UnitKind kind;

  /// 0-8 within the kind: row 4 is `UnitRef(UnitKind.row, 4)`.
  final int index;

  int get id => switch (kind) {
        UnitKind.row => index,
        UnitKind.column => 9 + index,
        UnitKind.box => 18 + index,
      };

  List<int> get cells => Units.unitCells[id];

  @override
  bool operator ==(Object other) =>
      other is UnitRef && other.kind == kind && other.index == index;

  @override
  int get hashCode => Object.hash(kind, index);

  @override
  String toString() => '${kind.name} ${index + 1}';
}

class Units {
  Units._();

  static const int cellCount = 81;
  static const int unitCount = 27;

  /// All nine digits as a bitmask: bit 0 is digit 1.
  static const int allDigits = 0x1FF;

  static int maskOf(int digit) => 1 << (digit - 1);

  /// The row unit index for each cell.
  static final List<int> rowOf =
      List<int>.unmodifiable([for (int i = 0; i < cellCount; i++) i ~/ 9]);

  static final List<int> colOf =
      List<int>.unmodifiable([for (int i = 0; i < cellCount; i++) i % 9]);

  static final List<int> boxOf = List<int>.unmodifiable([
    for (int i = 0; i < cellCount; i++) (i ~/ 27) * 3 + (i % 9) ~/ 3,
  ]);

  /// The 27 units as cell-index lists: rows 0-8, columns 9-17, boxes 18-26.
  static final List<List<int>> unitCells = List<List<int>>.unmodifiable([
    for (int r = 0; r < 9; r++)
      List<int>.unmodifiable([for (int c = 0; c < 9; c++) r * 9 + c]),
    for (int c = 0; c < 9; c++)
      List<int>.unmodifiable([for (int r = 0; r < 9; r++) r * 9 + c]),
    for (int b = 0; b < 9; b++)
      List<int>.unmodifiable([
        for (int i = 0; i < 9; i++)
          (b ~/ 3) * 27 + (b % 3) * 3 + (i ~/ 3) * 9 + (i % 3),
      ]),
  ]);

  /// The three unit ids each cell belongs to: row, then column, then box.
  static final List<List<int>> unitsOf = List<List<int>>.unmodifiable([
    for (int i = 0; i < cellCount; i++)
      List<int>.unmodifiable([rowOf[i], 9 + colOf[i], 18 + boxOf[i]]),
  ]);

  /// The 20 cells each cell shares a unit with, excluding itself.
  static final List<List<int>> peersOf = List<List<int>>.unmodifiable([
    for (int i = 0; i < cellCount; i++)
      List<int>.unmodifiable(<int>{
        for (final unitId in unitsOf[i]) ...unitCells[unitId],
      }..remove(i)),
  ]);

  static UnitKind unitKindOf(int unitId) => switch (unitId ~/ 9) {
        0 => UnitKind.row,
        1 => UnitKind.column,
        _ => UnitKind.box,
      };

  /// True when every cell in [cells] shares at least one unit with the others.
  /// Used by the intersection rules, where "these all lie in one box" is the
  /// whole deduction.
  static bool allShareUnit(Iterable<int> cells) => commonUnits(cells).isNotEmpty;

  /// The unit ids that contain every one of [cells]. Empty for cells that do
  /// not all see each other.
  static List<int> commonUnits(Iterable<int> cells) {
    final it = cells.iterator;
    if (!it.moveNext()) return const [];
    var common = unitsOf[it.current].toSet();
    while (it.moveNext()) {
      common = common.intersection(unitsOf[it.current].toSet());
      if (common.isEmpty) return const [];
    }
    return common.toList()..sort();
  }

  static int indexOf(int row, int col) => row * 9 + col;

  /// Digits present in a bitmask, ascending.
  static List<int> digitsIn(int mask) =>
      [for (int d = 1; d <= 9; d++) if (mask & maskOf(d) != 0) d];

  static int popCount(int mask) {
    int n = 0;
    while (mask != 0) {
      mask &= mask - 1;
      n++;
    }
    return n;
  }
}

import '../../engine/deduction/deduction.dart';
import '../../engine/deduction/units.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';
import 'hint_engine.dart';

enum GameStatus { playing, complete, abandoned }

/// An action that can be undone.
sealed class GameAction {
  const GameAction();
}

class PlaceNumber extends GameAction {
  final int row, col, value, previousValue;
  final Set<int> previousNotes;
  /// Notes cleared from related cells by auto-remove (for undo restoration).
  final Map<int, Set<int>> clearedNotes;
  const PlaceNumber(this.row, this.col, this.value, this.previousValue, this.previousNotes, this.clearedNotes);
}

class PlaceNote extends GameAction {
  final int row, col, noteValue;
  final bool wasAdded;
  const PlaceNote(this.row, this.col, this.noteValue, this.wasAdded);
}

class EraseCell extends GameAction {
  final int row, col, previousValue;
  final Set<int> previousNotes;
  const EraseCell(this.row, this.col, this.previousValue, this.previousNotes);
}

class UseHint extends GameAction {
  final int row, col, revealedValue, previousValue;
  final Set<int> previousNotes;
  final Map<int, Set<int>> clearedNotes;

  /// Where the hint stood before this rung was taken, so undo puts the
  /// explanation back rather than dumping the player at the start of it.
  ///
  /// The deduction itself is not carried: undo restores the board exactly, so
  /// the next look recomputes the identical step. Value equality makes that a
  /// guarantee rather than a hope.
  final int previousRungIndex;
  final int previousDepth;

  const UseHint(
    this.row,
    this.col,
    this.revealedValue,
    this.previousValue,
    this.previousNotes,
    this.clearedNotes, {
    this.previousRungIndex = 0,
    this.previousDepth = 0,
  });
}

/// H4 on an elimination: seed the notes it needs, then rub the candidates
/// out. One undoable action, because "remove 4 and 7" means nothing on a
/// cell showing no notes at all.
class ApplyElimination extends GameAction {
  const ApplyElimination(
    this.previousNotes, {
    this.previousRungIndex = 0,
    this.previousDepth = 0,
  });

  final Map<int, Set<int>> previousNotes;
  final int previousRungIndex;
  final int previousDepth;
}

class AutoFillNotes extends GameAction {
  final Map<int, Set<int>> previousNotes;
  const AutoFillNotes(this.previousNotes);
}

class GameState {
  final SudokuBoard puzzle;
  final SudokuBoard board;
  final SudokuBoard solution;
  final Set<int> givenCells;
  final String puzzleId;
  final Difficulty difficulty;
  final bool isDaily;
  final Map<int, Set<int>> notes;
  final List<GameAction> history;
  final int? selectedRow;
  final int? selectedCol;
  final bool isNotesMode;

  /// How many hints have been asked for. Unlimited — the cost is paid in
  /// [hintDepthTotal] against quality, not in a counter that runs out and
  /// leaves a stuck player with nowhere to go.
  final int hintsUsed;

  /// Sum of the rung cost of every hint taken. A nudge toward the right box
  /// costs 1; being handed the digit costs 6.
  final int hintDepthTotal;

  /// The step currently being explained, pinned so it does not move.
  ///
  /// Recomputing per tap would let the first tap say box 4 and the second say
  /// box 7, which reads as the app changing its mind. Cleared when its
  /// targets are all satisfied, or when a fresh look finds a different step.
  final Deduction? activeHint;

  /// How far [activeHint] has been pushed.
  final HintRung hintRung;

  /// The digit currently being previewed by a long-press on the number pad.
  ///
  /// Shows where that digit *could* go using nothing but row, column and box
  /// — the same elimination any player can do by looking. Deliberately not
  /// the engine's candidate state, which has had pairs, intersections and
  /// chains applied to it: that would quietly hand over reasoning the player
  /// came here to do.
  final int? previewDigit;

  /// Cells where [previewDigit] could legally go, by peers alone.
  Set<int> get previewCells {
    final digit = previewDigit;
    if (digit == null) return const {};
    final cells = <int>{};
    for (int i = 0; i < 81; i++) {
      if (board.get(i ~/ 9, i % 9) != 0) continue;
      if (board.isValid(i ~/ 9, i % 9, digit)) cells.add(i);
    }
    return cells;
  }

  /// Set when the player typed or pasted this grid in.
  ///
  /// An imported puzzle has no Difficulty, so no par time, so no quality
  /// score. It is an analysis tool rather than a scored mode: recording one
  /// would put a made-up difficulty and an ungradeable time into the stats
  /// the whole R0 wave existed to repair.
  final bool isImported;

  /// Set when this is a technique drill rather than a full puzzle.
  ///
  /// A drill is one move: the position has been fast-forwarded to the point
  /// where this technique applies, so it is finished as soon as that move is
  /// made. It is also the signal that the notes are engine-seeded scaffolding
  /// and therefore authoritative — the eliminations that set the pattern up
  /// exist nowhere else.
  final Technique? drillTechnique;

  bool get isDrill => drillTechnique != null;

  /// Neither drills nor imports are graded, and both skip the same writes.
  bool get isScored => !isDrill && !isImported;

  /// The move a drill is waiting for, if this is a drill.
  ///
  /// Pinned on the state rather than recomputed, so the completion check
  /// asks about the move the drill was built around and not whatever the
  /// ladder happens to prefer once the player has scribbled in the notes.
  final Deduction? activeDrillStep;

  /// Set when the hint system found a wrong digit rather than a deduction.
  final List<int> wrongCells;

  /// True when the current hint appeared on its own rather than being asked
  /// for. Unprompted help is free — charging quality for something the player
  /// never requested would be indefensible — but the moment they tap for more
  /// it becomes a hint like any other.
  final bool hintWasUnprompted;

  final int mistakeCount;
  final Duration elapsed;
  final GameStatus status;
  final bool isOnPbPace;

  // Digit-first input: the last digit selected from the number pad
  final int? selectedDigit;

  // Group completion flash: cell indices (row*9+col) that just completed a group
  final Set<int> completionFlashCells;

  // Preferences
  final bool highlightMatching;
  final bool showTimer;
  final bool autoRemoveNotes;
  final int mistakeLimit; // 0 = off
  final bool digitFirstInput;

  /// off = the hint button jumps straight to the answer, as it did before the
  /// rungs existed.
  final bool hintsExplain;

  /// off = the no-oracle mode. A digit reddens only when it breaks an actual
  /// row, column or box rule, not merely because it disagrees with the stored
  /// solution.
  final bool flagMistakesInstantly;

  /// off = no unprompted help at all.
  final bool nudgeWhenStuck;

  const GameState({
    required this.puzzle,
    required this.board,
    required this.solution,
    required this.givenCells,
    required this.puzzleId,
    required this.difficulty,
    this.isDaily = false,
    this.notes = const {},
    this.history = const [],
    this.selectedRow,
    this.selectedCol,
    this.isNotesMode = false,
    this.hintsUsed = 0,
    this.hintDepthTotal = 0,
    this.activeHint,
    this.hintRung = HintRung.locate,
    this.wrongCells = const [],
    this.hintWasUnprompted = false,
    this.previewDigit,
    this.isImported = false,
    this.drillTechnique,
    this.activeDrillStep,
    this.mistakeCount = 0,
    this.elapsed = Duration.zero,
    this.status = GameStatus.playing,
    this.isOnPbPace = false,
    this.selectedDigit,
    this.completionFlashCells = const {},
    this.highlightMatching = true,
    this.showTimer = false,
    this.autoRemoveNotes = true,
    this.mistakeLimit = 0,
    this.digitFirstInput = false,
    this.hintsExplain = true,
    this.flagMistakesInstantly = true,
    this.nudgeWhenStuck = true,
  });

  bool get hasSelection => selectedRow != null && selectedCol != null;

  int? get selectedIndex =>
      hasSelection ? selectedRow! * 9 + selectedCol! : null;

  /// The unit a hint names, shaded from the very first rung.
  ///
  /// "there's something in box 3" is useless to anyone who cannot say which
  /// box is box 3 — and the locate rung's entire job is to point. Shading the
  /// unit is that pointing, and it teaches the numbering at the same time:
  /// you are told a name and shown the thing it names.
  Set<int> get hintUnitCells {
    if (!hasHint) return const {};
    final unit = activeHint?.unit;
    if (unit != null) return unit.cells.toSet();
    // A wrong digit is pointed at by its box, which is what the copy says.
    if (wrongCells.isNotEmpty && hintRung.index >= HintRung.narrow.index) {
      return Units.unitCells[18 + Units.boxOf[wrongCells.first]].toSet();
    }
    return const {};
  }

  /// Cells the current hint is pointing at, once the rung is far enough
  /// along to point at anything.
  Set<int> get hintTargets => hintRung.index >= HintRung.narrow.index
      ? {...?activeHint?.cells, ...wrongCells.take(1)}
      : const {};

  /// Cells that prove the current hint. Shown from the explain rung on.
  Set<int> get hintWitnesses => hintRung.index >= HintRung.explain.index
      ? {...?activeHint?.witnesses}
      : const {};

  bool get hasHint => activeHint != null || wrongCells.isNotEmpty;

  int? get selectedValue {
    if (!hasSelection) return null;
    return board.get(selectedRow!, selectedCol!);
  }

  bool isGiven(int row, int col) => givenCells.contains(row * 9 + col);

  Set<int> notesAt(int row, int col) => notes[row * 9 + col] ?? const {};

  GameState copyWith({
    SudokuBoard? board,
    Map<int, Set<int>>? notes,
    List<GameAction>? history,
    int? Function()? selectedRow,
    int? Function()? selectedCol,
    bool? isNotesMode,
    int? hintsUsed,
    int? hintDepthTotal,
    Deduction? Function()? activeHint,
    HintRung? hintRung,
    List<int>? wrongCells,
    bool? hintWasUnprompted,
    int? Function()? previewDigit,
    int? mistakeCount,
    Duration? elapsed,
    GameStatus? status,
    bool? isOnPbPace,
    int? Function()? selectedDigit,
    Set<int>? completionFlashCells,
    bool? highlightMatching,
    bool? showTimer,
    bool? autoRemoveNotes,
    int? mistakeLimit,
    bool? digitFirstInput,
    bool? hintsExplain,
    bool? flagMistakesInstantly,
    bool? nudgeWhenStuck,
  }) {
    return GameState(
      puzzle: puzzle,
      board: board ?? this.board,
      solution: solution,
      givenCells: givenCells,
      puzzleId: puzzleId,
      difficulty: difficulty,
      isDaily: isDaily,
      notes: notes ?? this.notes,
      history: history ?? this.history,
      selectedRow: selectedRow != null ? selectedRow() : this.selectedRow,
      selectedCol: selectedCol != null ? selectedCol() : this.selectedCol,
      isNotesMode: isNotesMode ?? this.isNotesMode,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintDepthTotal: hintDepthTotal ?? this.hintDepthTotal,
      activeHint: activeHint != null ? activeHint() : this.activeHint,
      hintRung: hintRung ?? this.hintRung,
      wrongCells: wrongCells ?? this.wrongCells,
      hintWasUnprompted: hintWasUnprompted ?? this.hintWasUnprompted,
      previewDigit: previewDigit != null ? previewDigit() : this.previewDigit,
      isImported: isImported,
      drillTechnique: drillTechnique,
      activeDrillStep: activeDrillStep,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      elapsed: elapsed ?? this.elapsed,
      status: status ?? this.status,
      isOnPbPace: isOnPbPace ?? this.isOnPbPace,
      selectedDigit: selectedDigit != null ? selectedDigit() : this.selectedDigit,
      completionFlashCells: completionFlashCells ?? this.completionFlashCells,
      highlightMatching: highlightMatching ?? this.highlightMatching,
      showTimer: showTimer ?? this.showTimer,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
      digitFirstInput: digitFirstInput ?? this.digitFirstInput,
      hintsExplain: hintsExplain ?? this.hintsExplain,
      flagMistakesInstantly:
          flagMistakesInstantly ?? this.flagMistakesInstantly,
      nudgeWhenStuck: nudgeWhenStuck ?? this.nudgeWhenStuck,
    );
  }
}

import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';

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
  const UseHint(this.row, this.col, this.revealedValue, this.previousValue, this.previousNotes, this.clearedNotes);
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
  final int hintsRemaining;
  final int mistakeCount;
  final Duration elapsed;
  final GameStatus status;

  // Preferences
  final bool highlightMatching;
  final bool showTimer;
  final bool autoRemoveNotes;
  final int mistakeLimit; // 0 = off

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
    this.hintsRemaining = 3,
    this.mistakeCount = 0,
    this.elapsed = Duration.zero,
    this.status = GameStatus.playing,
    this.highlightMatching = true,
    this.showTimer = false,
    this.autoRemoveNotes = true,
    this.mistakeLimit = 0,
  });

  bool get hasSelection => selectedRow != null && selectedCol != null;

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
    int? hintsRemaining,
    int? mistakeCount,
    Duration? elapsed,
    GameStatus? status,
    bool? highlightMatching,
    bool? showTimer,
    bool? autoRemoveNotes,
    int? mistakeLimit,
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
      hintsRemaining: hintsRemaining ?? this.hintsRemaining,
      mistakeCount: mistakeCount ?? this.mistakeCount,
      elapsed: elapsed ?? this.elapsed,
      status: status ?? this.status,
      highlightMatching: highlightMatching ?? this.highlightMatching,
      showTimer: showTimer ?? this.showTimer,
      autoRemoveNotes: autoRemoveNotes ?? this.autoRemoveNotes,
      mistakeLimit: mistakeLimit ?? this.mistakeLimit,
    );
  }
}

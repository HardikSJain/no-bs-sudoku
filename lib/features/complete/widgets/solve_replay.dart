import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/a11y/tappable.dart';

import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../engine/sudoku_board.dart';
import '../../game/game_state.dart';

/// Replays the solve by animating through the action history.
class SolveReplay extends StatefulWidget {
  final SudokuBoard puzzle;
  final List<GameAction> history;

  const SolveReplay({
    super.key,
    required this.puzzle,
    required this.history,
  });

  @override
  State<SolveReplay> createState() => _SolveReplayState();
}

class _SolveReplayState extends State<SolveReplay> {
  late SudokuBoard _board;
  late List<GameAction> _visibleHistory;
  int _step = 0;
  Timer? _timer;
  bool _playing = false;
  int? _lastPlacedCell;

  @override
  void initState() {
    super.initState();
    _board = widget.puzzle.copy();
    _visibleHistory = widget.history.where((a) => a is! PlaceNote).toList();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _play() {
    _timer?.cancel();
    if (_step >= _visibleHistory.length) {
      // Reset and replay
      setState(() {
        _board = widget.puzzle.copy();
        _step = 0;
        _lastPlacedCell = null;
      });
    }
    setState(() => _playing = true);
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_step >= _visibleHistory.length) {
        _timer?.cancel();
        setState(() => _playing = false);
        return;
      }
      _applyStep();
    });
  }

  void _pause() {
    _timer?.cancel();
    setState(() => _playing = false);
  }

  void _applyStep() {
    final action = _visibleHistory[_step];
    switch (action) {
      case PlaceNumber(:final row, :final col, :final value):
        _board.set(row, col, value);
        _lastPlacedCell = row * 9 + col;
      case UseHint(:final row, :final col, :final revealedValue):
        _board.set(row, col, revealedValue);
        _lastPlacedCell = row * 9 + col;
      case ApplyElimination():
        // Notes-only, so the replay board does not change.
        break;
      case EraseCell(:final row, :final col):
        _board.set(row, col, 0);
        _lastPlacedCell = row * 9 + col;
      case PlaceNote():
        break; // filtered out, but exhaustive switch requires this
      case AutoFillNotes():
        break; // no board change — notes only
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final isComplete = _step >= _visibleHistory.length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Tappable(
              label: _playing ? 'pause the replay' : 'play the replay',
              onTap: _playing ? _pause : _play,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: col.paper,
                  border: Border.all(color: col.ink, width: 2),
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: col.cardShadow,
                ),
                child: Text(
                  _playing ? 'pause' : isComplete ? 'replay' : 'play',
                  style: AppTypography.labelSmall.copyWith(
                    color: col.ink,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
            ),
            if (_step > 0) ...[
              const SizedBox(width: 10),
              Text(
                '$_step / ${_visibleHistory.length} moves',
                style: AppTypography.labelSmall.copyWith(color: col.ink4, fontSize: 11),
              ),
            ],
          ],
        ),
        if (_playing || _step > 0) ...[
          const SizedBox(height: 12),
          Center(
            child: SizedBox(
              width: 198,
              height: 198,
              child: CustomPaint(
                painter: _MiniGridPainter(
                  board: _board,
                  givenCells: _givenCellSet,
                  lastPlaced: _lastPlacedCell,
                  col: col,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Set<int> get _givenCellSet {
    final given = <int>{};
    for (int i = 0; i < 81; i++) {
      if (widget.puzzle.get(i ~/ 9, i % 9) != 0) given.add(i);
    }
    return given;
  }
}

class _MiniGridPainter extends CustomPainter {
  final SudokuBoard board;
  final Set<int> givenCells;
  final int? lastPlaced;
  final AppThemeColors col;

  _MiniGridPainter({
    required this.board,
    required this.givenCells,
    required this.col,
    this.lastPlaced,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;

    final gridPaint = Paint()
      ..color = col.ink4.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    final boxPaint = Paint()
      ..color = col.ink3
      ..strokeWidth = 1.5;

    // Draw cells
    for (int i = 0; i < 81; i++) {
      final row = i ~/ 9;
      final c = i % 9;
      final value = board.get(row, c);
      final rect = Rect.fromLTWH(c * cellSize, row * cellSize, cellSize, cellSize);

      if (i == lastPlaced) {
        canvas.drawRect(rect, Paint()..color = col.mint.withValues(alpha: 0.4));
      }

      if (value != 0) {
        final isGiven = givenCells.contains(i);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$value',
            style: TextStyle(
              fontSize: cellSize * 0.55,
              color: isGiven ? col.ink4 : col.ink,
              fontWeight: isGiven ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(rect.center.dx - textPainter.width / 2, rect.center.dy - textPainter.height / 2),
        );
      }
    }

    // Grid lines
    for (int i = 0; i <= 9; i++) {
      final paint = (i % 3 == 0) ? boxPaint : gridPaint;
      final pos = i * cellSize;
      canvas.drawLine(Offset(pos, 0), Offset(pos, size.height), paint);
      canvas.drawLine(Offset(0, pos), Offset(size.width, pos), paint);
    }
  }

  @override
  bool shouldRepaint(_MiniGridPainter oldDelegate) => true;
}

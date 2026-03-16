import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
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
      case EraseCell(:final row, :final col):
        _board.set(row, col, 0);
        _lastPlacedCell = row * 9 + col;
      case PlaceNote():
        break; // filtered out, but exhaustive switch requires this
    }
    setState(() => _step++);
  }

  @override
  Widget build(BuildContext context) {
    final isComplete = _step >= _visibleHistory.length;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _playing ? _pause : _play,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border, width: 0.5),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              _playing
                  ? 'pause'
                  : isComplete
                      ? 'replay'
                      : 'watch solve',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
                fontSize: 11,
              ),
            ),
          ),
        ),
        if (_playing || _step > 0) ...[
          const SizedBox(height: 12),
          SizedBox(
            width: 180,
            height: 180,
            child: CustomPaint(
              painter: _MiniGridPainter(
                board: _board,
                givenCells: _givenCellSet,
                lastPlaced: _lastPlacedCell,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_step}/${_visibleHistory.length} moves',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textDisabled,
              fontSize: 10,
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

  _MiniGridPainter({
    required this.board,
    required this.givenCells,
    this.lastPlaced,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cellSize = size.width / 9;

    final gridPaint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 0.5;

    final boxPaint = Paint()
      ..color = AppColors.textDisabled
      ..strokeWidth = 1.5;

    // Draw cells
    for (int i = 0; i < 81; i++) {
      final row = i ~/ 9;
      final col = i % 9;
      final value = board.get(row, col);
      final rect = Rect.fromLTWH(
        col * cellSize,
        row * cellSize,
        cellSize,
        cellSize,
      );

      // Highlight last placed cell
      if (i == lastPlaced) {
        canvas.drawRect(
          rect,
          Paint()..color = AppColors.accent.withValues(alpha: 0.3),
        );
      }

      if (value != 0) {
        final isGiven = givenCells.contains(i);
        final textPainter = TextPainter(
          text: TextSpan(
            text: '$value',
            style: TextStyle(
              fontSize: cellSize * 0.55,
              color: isGiven ? AppColors.textDisabled : AppColors.textPrimary,
              fontWeight: isGiven ? FontWeight.w400 : FontWeight.w600,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        textPainter.paint(
          canvas,
          Offset(
            rect.center.dx - textPainter.width / 2,
            rect.center.dy - textPainter.height / 2,
          ),
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

import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_theme_colors.dart';
import '../theme/app_typography.dart';

class GridLoader extends StatefulWidget {
  const GridLoader({super.key});

  @override
  State<GridLoader> createState() => _GridLoaderState();
}

class _GridLoaderState extends State<GridLoader> {
  static const _numbers = [5, 3, 7, 9, 2, 8, 1, 6, 4];
  int _step = 0;
  bool _fading = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _nextStep();
  }

  void _nextStep() {
    _timer = Timer(const Duration(milliseconds: 150), () {
      if (!mounted) return;
      setState(() => _step++);
      if (_step < 9) {
        _nextStep();
      } else {
        _timer = Timer(const Duration(milliseconds: 600), () {
          if (!mounted) return;
          setState(() => _fading = true);
          _timer = Timer(const Duration(milliseconds: 280), () {
            if (!mounted) return;
            setState(() {
              _step = 0;
              _fading = false;
            });
            _nextStep();
          });
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Color _bgFor(AppThemeColors col, int idx) {
    if (_step <= idx) return col.paper;
    return switch (idx) {
      4 => col.accent,
      2 => col.sun,
      6 => col.mint,
      _ => col.paper,
    };
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    const cellSize = 48.0;
    const gap = 5.0;

    return AnimatedOpacity(
      opacity: _fading ? 0.0 : 1.0,
      duration: const Duration(milliseconds: 250),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (row) => Padding(
          padding: EdgeInsets.only(bottom: row < 2 ? gap : 0),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (c) {
              final idx = row * 3 + c;
              final revealed = _step > idx;
              final bg = _bgFor(col, idx);
              final numColor = idx == 4 ? Colors.white : col.ink;
              return Padding(
                padding: EdgeInsets.only(right: c < 2 ? gap : 0),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: cellSize,
                  height: cellSize,
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: col.ink, width: 2),
                    boxShadow: [BoxShadow(color: col.ink, offset: const Offset(2, 2), blurRadius: 0)],
                  ),
                  child: Center(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 180),
                      transitionBuilder: (child, anim) => ScaleTransition(
                        scale: Tween(begin: 0.5, end: 1.0).animate(
                          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                        ),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: revealed
                          ? Text(
                              '${_numbers[idx]}',
                              key: const ValueKey(true),
                              style: AppTypography.number.copyWith(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: numColor,
                              ),
                            )
                          : const SizedBox.shrink(key: ValueKey(false)),
                    ),
                  ),
                ),
              );
            }),
          ),
        )),
      ),
    );
  }
}

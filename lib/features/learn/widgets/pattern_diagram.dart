import 'package:flutter/material.dart';

import '../../../core/theme/app_theme_colors.dart';

/// A small 9x9 schematic of one technique's shape.
///
/// Several techniques are spatial — a swordfish is three rows lining up
/// across three columns — and no amount of careful prose replaces seeing the
/// shape once. Three roles: the unit the argument happens inside, the cells
/// that make the pattern, and what it settles or rules out.
class PatternDiagram extends StatelessWidget {
  const PatternDiagram({
    super.key,
    required this.context_,
    required this.witnesses,
    required this.targets,
    this.size = 132,
  });

  final List<int> context_;
  final List<int> witnesses;
  final List<int> targets;
  final double size;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _PatternPainter(
          context_: context_.toSet(),
          witnesses: witnesses.toSet(),
          targets: targets.toSet(),
          line: col.ink.withValues(alpha: 0.18),
          band: col.ink,
          contextFill: col.ink4.withValues(alpha: 0.13),
          witnessFill: col.sun,
          targetFill: col.error.withValues(alpha: 0.4),
        ),
      ),
    );
  }
}

class _PatternPainter extends CustomPainter {
  _PatternPainter({
    required this.context_,
    required this.witnesses,
    required this.targets,
    required this.line,
    required this.band,
    required this.contextFill,
    required this.witnessFill,
    required this.targetFill,
  });

  final Set<int> context_;
  final Set<int> witnesses;
  final Set<int> targets;
  final Color line;
  final Color band;
  final Color contextFill;
  final Color witnessFill;
  final Color targetFill;

  @override
  void paint(Canvas canvas, Size size) {
    final cell = size.width / 9;
    final fill = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < 81; i++) {
      // A cell can be both context and witness; the stronger role wins, which
      // is why these are checked hardest-first rather than blended.
      final Color? c = witnesses.contains(i)
          ? witnessFill
          : targets.contains(i)
              ? targetFill
              : context_.contains(i)
                  ? contextFill
                  : null;
      if (c == null) continue;
      fill.color = c;
      canvas.drawRect(
        Rect.fromLTWH((i % 9) * cell, (i ~/ 9) * cell, cell, cell),
        fill,
      );
    }

    final thin = Paint()
      ..color = line
      ..strokeWidth = 0.5;
    final thick = Paint()
      ..color = band
      ..strokeWidth = 1.4;

    for (int i = 0; i <= 9; i++) {
      final p = i * cell;
      final paint = i % 3 == 0 ? thick : thin;
      canvas.drawLine(Offset(p, 0), Offset(p, size.height), paint);
      canvas.drawLine(Offset(0, p), Offset(size.width, p), paint);
    }
  }

  @override
  bool shouldRepaint(_PatternPainter old) =>
      old.witnesses != witnesses ||
      old.targets != targets ||
      old.context_ != context_ ||
      old.witnessFill != witnessFill;
}

/// The key that makes the diagram readable without a caption.
class PatternLegend extends StatelessWidget {
  const PatternLegend({super.key, required this.hasTargets});

  final bool hasTargets;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    Widget swatch(Color c, String label) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: c,
                borderRadius: BorderRadius.circular(2),
                border: Border.all(color: col.ink, width: 1),
              ),
            ),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                    color: col.ink4, fontSize: 9, letterSpacing: 0.2)),
          ],
        );

    return Wrap(
      spacing: 12,
      runSpacing: 4,
      children: [
        swatch(col.sun, 'the pattern'),
        if (hasTargets) swatch(col.error.withValues(alpha: 0.4), 'what it settles'),
      ],
    );
  }
}

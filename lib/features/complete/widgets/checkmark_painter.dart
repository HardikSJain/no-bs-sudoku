import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class CheckmarkPainter extends CustomPainter {
  final double progress;

  CheckmarkPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0) return;

    final path = Path()
      ..moveTo(size.width * 0.2, size.height * 0.5)
      ..lineTo(size.width * 0.45, size.height * 0.75)
      ..lineTo(size.width * 0.8, size.height * 0.25);

    final metrics = path.computeMetrics().first;
    final drawn = metrics.extractPath(0, metrics.length * progress);

    canvas.drawPath(
      drawn,
      Paint()
        ..color = AppColors.accent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(CheckmarkPainter old) => old.progress != progress;
}

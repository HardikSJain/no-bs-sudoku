import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class PerformanceSparkline extends StatelessWidget {
  final List<PuzzleRecord> last14Days;

  const PerformanceSparkline({super.key, required this.last14Days});

  @override
  Widget build(BuildContext context) {
    if (last14Days.isEmpty) return const SizedBox.shrink();

    final col = context.appColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayMap = <int, List<double>>{};
    for (final r in last14Days) {
      final d = DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day);
      final dayIndex = 13 - today.difference(d).inDays;
      if (dayIndex >= 0 && dayIndex <= 13) {
        dayMap.putIfAbsent(dayIndex, () => []).add(r.qualityScore);
      }
    }

    final spots = <FlSpot>[];
    for (final entry in dayMap.entries) {
      final avg = entry.value.reduce((a, b) => a + b) / entry.value.length;
      spots.add(FlSpot(entry.key.toDouble(), avg));
    }
    spots.sort((a, b) => a.x.compareTo(b.x));

    if (spots.length < 2) return const SizedBox.shrink();

    final gridColor = col.isLight
        ? col.ink4.withValues(alpha: 0.5)
        : col.outline;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'performance trend',
          style: AppTypography.label.copyWith(color: col.textSecondary),
        ),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: LineChart(
            LineChartData(
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: 25,
                getDrawingHorizontalLine: (_) => FlLine(
                  color: gridColor,
                  strokeWidth: col.isLight ? 1 : 0.5,
                ),
              ),
              titlesData: const FlTitlesData(show: false),
              borderData: FlBorderData(show: false),
              minY: 0,
              maxY: 100,
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  curveSmoothness: 0.2,
                  color: col.accent,
                  barWidth: col.isLight ? 2.5 : 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 3,
                      color: col.accent,
                      strokeWidth: col.isLight ? 1.5 : 0,
                      strokeColor: col.ink,
                    ),
                  ),
                  belowBarData: BarAreaData(show: false),
                ),
              ],
              lineTouchData: const LineTouchData(enabled: false),
            ),
          ),
        ),
      ],
    );
  }
}

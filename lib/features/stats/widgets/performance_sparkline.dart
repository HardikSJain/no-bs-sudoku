import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class PerformanceSparkline extends StatelessWidget {
  final List<PuzzleRecord> last14Days;

  const PerformanceSparkline({super.key, required this.last14Days});

  @override
  Widget build(BuildContext context) {
    if (last14Days.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group by day, compute avg quality per day
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'performance trend',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
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
                  color: AppColors.border,
                  strokeWidth: 0.5,
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
                  color: AppColors.accent,
                  barWidth: 2,
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (_, _, _, _) => FlDotCirclePainter(
                      radius: 3,
                      color: AppColors.accent,
                      strokeWidth: 0,
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

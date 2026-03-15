import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class ActivityHeatmap extends StatelessWidget {
  final List<PuzzleRecord> allRecords;

  const ActivityHeatmap({super.key, required this.allRecords});

  @override
  Widget build(BuildContext context) {
    if (allRecords.isEmpty) return const SizedBox.shrink();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Group records by day → avg quality
    final dayQuality = <DateTime, double>{};
    final dayGroups = <DateTime, List<double>>{};
    for (final r in allRecords) {
      final d = DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day);
      if (today.difference(d).inDays > 90) continue;
      dayGroups.putIfAbsent(d, () => []).add(r.qualityScore);
    }
    for (final entry in dayGroups.entries) {
      dayQuality[entry.key] =
          entry.value.reduce((a, b) => a + b) / entry.value.length;
    }

    // Build 13 weeks × 7 days grid (Monday = top)
    // Find the Monday 13 weeks ago
    final startOffset = today.weekday - 1; // days since Monday this week
    final gridStart = today.subtract(Duration(days: 12 * 7 + startOffset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'consistency',
          style: AppTypography.label.copyWith(color: AppColors.textSecondary),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 7 * 13.0, // 7 rows × (10 + 3 gap)
          child: Row(
            children: List.generate(13, (week) {
              return Expanded(
                child: Column(
                  children: List.generate(7, (day) {
                    final cellDate = gridStart.add(Duration(days: week * 7 + day));
                    if (cellDate.isAfter(today)) {
                      return const Expanded(child: SizedBox.shrink());
                    }
                    final quality = dayQuality[cellDate];
                    final hasData = quality != null;
                    final opacity = hasData
                        ? 0.3 + (quality / 100) * 0.7
                        : 1.0;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: hasData
                              ? AppColors.accent.withValues(alpha: opacity)
                              : AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    );
                  }),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

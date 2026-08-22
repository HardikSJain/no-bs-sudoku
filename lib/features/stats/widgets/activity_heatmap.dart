import 'package:flutter/material.dart';

import '../../../core/storage/app_database.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class ActivityHeatmap extends StatelessWidget {
  final List<PuzzleRecord> allRecords;

  const ActivityHeatmap({super.key, required this.allRecords});

  @override
  Widget build(BuildContext context) {
    if (allRecords.isEmpty) return const SizedBox.shrink();

    final col = context.appColors;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final dayGroups = <DateTime, List<double>>{};
    for (final r in allRecords) {
      final d = DateTime(r.completedAt.year, r.completedAt.month, r.completedAt.day);
      if (today.difference(d).inDays > 90) continue;
      dayGroups.putIfAbsent(d, () => []).add(r.qualityScore);
    }
    final dayQuality = {
      for (final e in dayGroups.entries)
        e.key: e.value.reduce((a, b) => a + b) / e.value.length,
    };

    final startOffset = today.weekday - 1;
    final gridStart = today.subtract(Duration(days: 12 * 7 + startOffset));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('consistency', style: AppTypography.label.copyWith(color: col.textSecondary)),
        const SizedBox(height: 12),
        SizedBox(
          height: 7 * 13.0,
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
                    final opacity = hasData ? 0.55 + (quality / 100) * 0.45 : 1.0;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.all(1.5),
                        decoration: BoxDecoration(
                          color: hasData
                              ? col.accent.withValues(alpha: opacity)
                              : col.ink4.withValues(alpha: 0.35),
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

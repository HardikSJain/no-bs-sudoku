import 'package:flutter/material.dart';

import '../../../core/duration_format.dart';
import '../../../core/theme/app_theme_colors.dart';
import '../../../core/theme/app_typography.dart';

class StatsGrid extends StatelessWidget {
  final String time;
  final int hints;
  final int mistakes;
  final int? pbDiffSeconds;
  final int? avgDiffSeconds;

  const StatsGrid({
    super.key,
    required this.time,
    required this.hints,
    required this.mistakes,
    this.pbDiffSeconds,
    this.avgDiffSeconds,
  });

  String _mistakeSub(int n) {
    if (n == 0) return 'clean solve';
    if (n <= 2) return 'recoverable';
    if (n <= 5) return 'rough';
    return 'chaos mode';
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    String avgValue = '—';
    String? avgSub;
    if (avgDiffSeconds != null) {
      avgValue = deltaTime(avgDiffSeconds!);
      avgSub = avgDiffSeconds! >= 0 ? 'faster than avg' : 'slower than avg';
    }

    String? timeSub;
    if (pbDiffSeconds != null) {
      // Only ever set on a new personal best, so it is always a beat and
      // deltaTime's minus is the right sign.
      timeSub = '${deltaTime(pbDiffSeconds!)} vs best';
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StatCard(col: col, label: 'TIME', value: time, sub: timeSub, subAccent: true)),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(col: col, label: 'HINTS', value: '$hints/3', sub: hints == 0 ? 'none used' : '$hints used')),
            ],
          ),
        ),
        const SizedBox(height: 10),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _StatCard(col: col, label: 'MISTAKES', value: '$mistakes', sub: _mistakeSub(mistakes))),
              const SizedBox(width: 10),
              Expanded(child: _StatCard(col: col, label: 'VS AVG', value: avgValue, sub: avgSub ?? 'play more to unlock')),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final AppThemeColors col;
  final String label;
  final String value;
  final String? sub;
  final bool subAccent;

  const _StatCard({
    required this.col,
    required this.label,
    required this.value,
    this.sub,
    this.subAccent = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: col.paper,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: col.ink, width: 2),
        boxShadow: col.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: col.ink3,
              fontSize: 10,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: AppTypography.number.copyWith(
              color: col.ink,
              fontSize: 22,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
            ),
          ),
          if (sub != null) ...[
            const SizedBox(height: 3),
            Text(
              sub!,
              style: AppTypography.labelSmall.copyWith(
                color: subAccent ? col.accent : col.ink3,
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/a11y/tappable.dart';
import '../../core/daily_key.dart';
import '../../core/haptics.dart';
import '../../core/logger.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_back_button.dart';
import '../../core/widgets/discard_confirmation.dart';
import 'daily_archive_cubit.dart';

/// Every daily still on offer, as a calendar.
///
/// A daily puzzle you can only play on the day is a daily puzzle you stop
/// playing the first time life gets in the way. Nothing had to be stored to
/// make this work — the same date has always produced the same puzzle — so
/// the only thing standing between a player and the one they missed on
/// Tuesday was a screen.
class DailyArchiveScreen extends StatelessWidget {
  const DailyArchiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => DailyArchiveCubit(
        records: ctx.read<PuzzleRecordRepository>(),
        savedGames: ctx.read<SavedGameRepository>(),
      ),
      child: const _ArchiveView(),
    );
  }
}

class _ArchiveView extends StatelessWidget {
  const _ArchiveView();

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;

    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<DailyArchiveCubit, DailyArchiveState>(
          builder: (context, state) {
            if (!state.loaded) return const SizedBox.shrink();

            // Newest month first: what you missed last week is what you came
            // here for, not what you missed in May.
            final months = _byMonth(state.days).reversed.toList();

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md, 10, AppSpacing.md, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const AppBackButton(label: 'back to home'),
                            const Spacer(),
                            _Summary(state: state, col: col),
                          ],
                        ),
                        const SizedBox(height: 18),
                        Text('past dailies.',
                            style: AppTypography.wordmark.copyWith(
                                color: col.ink,
                                fontSize: 26,
                                fontWeight: FontWeight.w700)),
                        const SizedBox(height: 6),
                        Text(
                          'the last $dailyArchiveDays days. same puzzle '
                          'everyone else got that day.',
                          style: AppTypography.labelSmall
                              .copyWith(color: col.ink3, height: 1.4),
                        ),
                        const SizedBox(height: 22),
                        _Legend(col: col),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ),
                for (final month in months)
                  SliverToBoxAdapter(
                    child: _MonthBlock(days: month, col: col),
                  ),
                const SliverToBoxAdapter(child: SizedBox(height: 40)),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Groups the flat run of days into months, oldest first, each month's days
  /// still in date order.
  List<List<ArchiveDay>> _byMonth(List<ArchiveDay> days) {
    final out = <List<ArchiveDay>>[];
    for (final day in days) {
      if (out.isEmpty ||
          out.last.first.date.month != day.date.month ||
          out.last.first.date.year != day.date.year) {
        out.add([day]);
      } else {
        out.last.add(day);
      }
    }
    return out;
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state, required this.col});

  final DailyArchiveState state;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    return MergeSemantics(
      child: Semantics(
        label: '${state.solvedCount} of ${state.days.length} solved',
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: col.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: col.ink, width: 1.5),
          ),
          child: Text(
            '${state.solvedCount} / ${state.days.length}',
            style: AppTypography.number.copyWith(
                color: col.ink, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.col});

  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    // Excluded from semantics: it is a key for the colours, and a screen
    // reader is told each day's state in words instead.
    return ExcludeSemantics(
      child: Wrap(
        spacing: 14,
        runSpacing: 8,
        children: [
          _LegendItem(col: col, fill: col.mint, label: 'solved'),
          _LegendItem(col: col, fill: col.sun, label: 'in progress'),
          _LegendItem(col: col, fill: col.paper, label: 'not played'),
        ],
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem(
      {required this.col, required this.fill, required this.label});

  final AppThemeColors col;
  final Color fill;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: col.ink, width: 1.5),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTypography.labelSmall
                .copyWith(color: col.ink3, fontSize: 10)),
      ],
    );
  }
}

class _MonthBlock extends StatelessWidget {
  const _MonthBlock({required this.days, required this.col});

  final List<ArchiveDay> days;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    final first = days.first.date;
    final title = DateFormat('MMMM yyyy').format(first).toLowerCase();

    // A calendar is only readable if the columns are weekdays, so the first
    // row is padded out to the right one. Monday-first, matching the daily's
    // own difficulty rotation.
    final lead = first.weekday - DateTime.monday;

    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.md, 0, AppSpacing.md, AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: AppTypography.labelSmall.copyWith(
                  color: col.ink3,
                  fontSize: 10,
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ExcludeSemantics(
            child: Row(
              children: [
                for (final d in ['m', 't', 'w', 't', 'f', 's', 's'])
                  Expanded(
                    child: Center(
                      child: Text(d,
                          style: AppTypography.labelSmall
                              .copyWith(color: col.ink4, fontSize: 9)),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          // Seven columns of a fixed width is the same constraint the board
          // has: the cells cannot grow, so the digits inside them cannot
          // either. Same clamp, same reason.
          MediaQuery(
            data: MediaQuery.of(context).copyWith(
              textScaler: TextScale.clampFor(context, TextScale.boardMax),
            ),
            child: GridView.count(
              crossAxisCount: 7,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              // A shade taller than wide: the cell carries a date and a tier
              // letter, and a square one clips the second at 1.3x.
              childAspectRatio: 0.82,
              children: [
                for (var i = 0; i < lead; i++) const SizedBox.shrink(),
                for (final day in days) _DayCell(day: day, col: col),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.col});

  final ArchiveDay day;
  final AppThemeColors col;

  @override
  Widget build(BuildContext context) {
    final fill = day.isSolved
        ? col.mint
        : day.inProgress
            ? col.sun
            : col.paper;

    return Tappable(
      label: _semanticLabel,
      hint: day.isSolved ? 'play it again' : 'play this one',
      onTap: () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: col.ink,
            // Today gets the heavier edge. It is the one day the rest of the
            // app is also talking about.
            width: day.isToday ? 2.5 : 1.5,
          ),
          boxShadow: day.isToday
              ? [BoxShadow(color: col.ink, offset: const Offset(2, 2))]
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '${day.date.day}',
              style: AppTypography.number.copyWith(
                color: col.ink,
                fontSize: 14,
                fontWeight: day.isToday ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
            // The tier, as one letter. A player who only wants the easy ones
            // can find them without opening ninety puzzles.
            Text(
              day.difficulty.letter,
              style: AppTypography.labelSmall.copyWith(
                color: col.difficultyColor(day.difficulty.name),
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _semanticLabel {
    final date = DateFormat('EEEE d MMMM').format(day.date).toLowerCase();
    final state = day.isSolved
        ? 'solved in ${spokenDuration(day.record!.timeSeconds)}'
        : day.inProgress
            ? 'in progress'
            : 'not played';
    return '$date, ${day.difficulty.name}, $state'
        '${day.isToday ? ', today' : ''}';
  }

  Future<void> _open(BuildContext context) async {
    Haptics.select();

    final saved = await context.read<SavedGameRepository>().getSavedGames();
    if (!context.mounted) return;

    // Tapping the day you are already part-way through means carry on, not
    // throw it away.
    if (day.inProgress && saved.daily != null) {
      context.push('/game/resume', extra: saved.daily);
      return;
    }

    // Only the daily slot is at risk. A quick game in the other one carries
    // on untouched, which is the whole point of there being two.
    if (!await confirmDiscard(context, saved.daily)) return;
    if (!context.mounted) return;

    Log.archiveDailyStarted(
      difficulty: day.difficulty.name,
      daysAgo: todayUtc().difference(day.date).inDays,
      replay: day.isSolved,
    );
    await context.read<SavedGameRepository>().deleteSavedGame(isDaily: true);
    if (!context.mounted) return;
    context.push('/game/daily/${day.id}');
  }
}

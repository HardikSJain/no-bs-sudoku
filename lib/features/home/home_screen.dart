import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../core/intelligence/intelligence_engine.dart';
import '../../core/daily_key.dart';
import '../../core/logger.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme_colors.dart';
import '../../core/a11y/tappable.dart';
import '../../core/duration_format.dart';
import '../../core/theme/app_typography.dart';
import '../game/technique_copy.dart';
import '../learn/technique_guide.dart';
import '../../engine/sudoku_solver.dart';
import 'home_cubit.dart';
import 'widgets/daily_puzzle_card.dart';
import 'widgets/stats_strip.dart';
import '../../core/widgets/discard_confirmation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) {
        final records = ctx.read<PuzzleRecordRepository>();
        final profiles = ctx.read<ProfileRepository>();
        return HomeCubit(
          records: records,
          profiles: profiles,
          savedGames: ctx.read<SavedGameRepository>(),
          intelligence: IntelligenceEngine(records, profiles),
        );
      },
      child: const _HomeView(),
    );
  }
}

class _HomeView extends StatefulWidget {
  const _HomeView();

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<HomeCubit>().load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            return Stack(
              children: [
                SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    0,
                    AppSpacing.md,
                    _resumeBarHeight(state),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      const SizedBox(height: AppSpacing.lg),
                      DailyPuzzleCard(
                        completed: state.dailyCompleted,
                        timeSeconds: state.dailyTimeSeconds,
                        difficulty: state.dailyDifficulty,
                        puzzleNum: state.dailyPuzzleNum,
                        onTap: () => _startDaily(context),
                        // Only today's. An archive daily in progress lives
                        // on the calendar and in the resume bar; putting it
                        // on this card would say it was today's puzzle.
                        inProgressGame:
                            (!state.dailyCompleted && _isTodaysDaily(state))
                                ? state.saved.daily
                                : null,
                      ),
                      const SizedBox(height: 8),
                      _buildArchiveLink(context),
                      const SizedBox(height: AppSpacing.lg),
                      _buildDifficultySection(context, state),
                      const SizedBox(height: AppSpacing.lg),
                      StatsStrip(
                        currentStreak: state.currentStreak,
                        totalSolved: state.totalSolved,
                        avgQuality: state.avgQuality,
                        onTap: () => context.push('/stats'),
                      ),
                      if (state.insight != null) ...[
                        const SizedBox(height: AppSpacing.md),
                        Builder(builder: (ctx) => Text(
                          state.insight!,
                          style: AppTypography.labelSmall.copyWith(
                            color: ctx.appColors.textSecondary,
                            fontStyle: FontStyle.italic,
                            fontSize: 12,
                          ),
                        )),
                      ],
                      _buildFooter(context),
                    ],
                  ),
                ),
                if (_resumable(state).isNotEmpty)
                  Positioned(
                    left: AppSpacing.md,
                    right: AppSpacing.md,
                    bottom: AppSpacing.md,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (final saved in _resumable(state)) ...[
                          _buildResumeBar(context, saved),
                          if (saved != _resumable(state).last)
                            const SizedBox(height: 8),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  /// Whether the daily slot is holding today's puzzle rather than one from
  /// the archive.
  bool _isTodaysDaily(HomeState state) =>
      state.saved.daily?.puzzleId == dailyPuzzleId();

  /// The games the resume bar offers, newest first.
  ///
  /// Today's daily is not among them: the daily card directly above already
  /// shows it, with its own resume button, and two buttons for one puzzle is
  /// two chances to wonder which is which.
  List<SavedGame> _resumable(HomeState state) {
    final games = <SavedGame>[
      if (state.saved.daily != null && !_isTodaysDaily(state))
        state.saved.daily!,
      if (state.saved.other != null) state.saved.other!,
    ];
    games.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return games;
  }

  /// Room under the scroll for however many bars there are.
  double _resumeBarHeight(HomeState state) => switch (_resumable(state).length) {
        0 => 0,
        1 => 80,
        _ => 152,
      };

  /// What the bar calls this game.
  ///
  /// The tier alone is not enough once two bars can be on screen: "medium"
  /// and "easy" side by side give no clue that one of them is a daily from
  /// last Thursday.
  String _describeSave(SavedGame saved) {
    if (!saved.isDaily) return saved.difficulty;
    final date = parseDailyPuzzleId(saved.puzzleId);
    if (date == null || date == todayUtc()) return "today's daily";
    return 'daily, ${DateFormat('d MMM').format(date).toLowerCase()}';
  }

  /// Throws away a puzzle from the resume bar, after asking.
  ///
  /// Asks even though the button is small and deliberate, because the thing
  /// on the other side of it is an hour of somebody's evening and there is no
  /// undo once the row is gone.
  Future<void> _dismiss(BuildContext context, SavedGame saved) async {
    HapticFeedback.lightImpact();
    final cubit = context.read<HomeCubit>();
    final ok = await confirmDiscard(
      context,
      saved,
      reason: 'this cannot be undone.',
    );
    if (!ok) return;
    await cubit.dismissSavedGame(isDaily: saved.isDaily);
  }

  Widget _buildResumeBar(BuildContext context, SavedGame saved) {
    final col = context.appColors;
    final time = clockTime(saved.elapsedSeconds);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 10, 10),
      decoration: BoxDecoration(
        color: col.ink,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: col.mint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'IN PROGRESS',
                  style: AppTypography.labelSmall.copyWith(
                    color: Colors.white.withValues(alpha: 0.5),
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                Text(
                  '${_describeSave(saved)}  ·  $time',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.label.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Tappable(
            label: 'continue ${describeSavedGame(saved)}, '
                '${spokenDuration(saved.elapsedSeconds)} in',
            onTap: () {
              HapticFeedback.lightImpact();
              context.push('/game/resume', extra: saved);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
              decoration: BoxDecoration(
                color: col.sun,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'CONTINUE →',
                style: AppTypography.labelSmall.copyWith(
                  color: col.ink,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          // The only way out of a puzzle you have decided not to finish.
          // Without it the bar could be continued and nothing else, and the
          // only way to clear one was to start another game and discard it
          // in the sheet — which is a strange way to say "no thanks".
          //
          // Set apart from CONTINUE rather than tucked against it: they are
          // a hand's width apart on purpose, because one of them is
          // irreversible.
          const SizedBox(width: 4),
          Tappable(
            label: 'discard ${describeSavedGame(saved)}',
            hint: 'throw this puzzle away',
            onTap: () => _dismiss(context, saved),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              child: Icon(
                Icons.close,
                size: 16,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ),
        ],
      ),
    )
        .animate()
        .slideY(begin: 1, end: 0, duration: 300.ms, curve: Curves.easeOutCubic)
        .fadeIn(duration: 200.ms);
  }

  Widget _buildHeader(BuildContext context) {
    final col = context.appColors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, AppSpacing.xl, 0, AppSpacing.lg),
      child: Row(
        children: [
          Text(
            'no bs sudoku',
            style: AppTypography.wordmark.copyWith(
              color: col.textSecondary,
              fontSize: 15,
              fontWeight: FontWeight.w400,
              letterSpacing: 0.3,
            ),
          ),
          const Spacer(),
          Tappable(
            label: 'settings',
            onTap: () => context.push('/settings'),
            child: SizedBox(
              width: 44,
              height: 44,
              child: Center(
                child: Icon(
                  Icons.settings_outlined,
                  color: col.textSecondary,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDifficultySection(BuildContext context, HomeState state) {
    // The four ceiling labels only. The deep tiers live on their own shelf
    // below: six cards would mean three rows and would put a puzzle that
    // *requires* an x-wing in front of every beginner as though it were a
    // normal choice.
    final difficulties = Difficulty.classic;
    final col = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'NEW GAME',
          style: AppTypography.labelSmall.copyWith(
            color: col.ink3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _DifficultyCard(
                index: 0,
                difficulty: difficulties[0],
                isRecommended: state.recommendedDifficulty == difficulties[0],
                bestTimeSecs: state.bestTimes[difficulties[0].name],
                onTap: () => _startGame(context, difficulties[0]),
              ).animate(delay: 0.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DifficultyCard(
                index: 1,
                difficulty: difficulties[1],
                isRecommended: state.recommendedDifficulty == difficulties[1],
                bestTimeSecs: state.bestTimes[difficulties[1].name],
                onTap: () => _startGame(context, difficulties[1]),
              ).animate(delay: 40.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _DifficultyCard(
                index: 2,
                difficulty: difficulties[2],
                isRecommended: state.recommendedDifficulty == difficulties[2],
                bestTimeSecs: state.bestTimes[difficulties[2].name],
                onTap: () => _startGame(context, difficulties[2]),
              ).animate(delay: 80.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _DifficultyCard(
                index: 3,
                difficulty: difficulties[3],
                isRecommended: state.recommendedDifficulty == difficulties[3],
                bestTimeSecs: state.bestTimes[difficulties[3].name],
                onTap: () => _startGame(context, difficulties[3]),
              ).animate(delay: 120.ms).fadeIn(duration: 200.ms).slideY(begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
            ),
          ],
        ),
        const SizedBox(height: 22),
        _buildDeepSection(context, state),
      ],
    );
  }

  /// The two technique-defined tiers, set apart from the main grid.
  ///
  /// Kept visually distinct and below the fold of the primary choice so the
  /// new game decision stays a four-way one. Named by technique on purpose:
  /// an enthusiast reads "chains" as a promise, and someone who does not
  /// recognise the word correctly infers it is not for them yet.
  Widget _buildDeepSection(BuildContext context, HomeState state) {
    final col = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'GOING DEEPER',
          style: AppTypography.labelSmall.copyWith(
            color: col.ink3,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'puzzles that need a technique, not just patience.',
          style: AppTypography.labelSmall
              .copyWith(color: col.ink4, fontSize: 10),
        ),
        const SizedBox(height: 10),
        Tappable(
          label: 'learn a technique. what each pattern is, and how well you '
              'know it',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/learn');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: col.accent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.ink, width: 2),
              boxShadow: col.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'learn a technique',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'what each pattern is, and how well you know it',
                        style: AppTypography.labelSmall.copyWith(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 9),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.white, size: 18),
              ],
            ),
          ),
        ),
        // Quieter than the learn card above it: bringing your own puzzle is a
        // thing you go looking for, not something to put in front of someone
        // who came to play.
        Tappable(
          label: 'import a puzzle',
          hint: 'type or paste one from elsewhere. it will not count towards '
              'your stats',
          onTap: () {
            HapticFeedback.lightImpact();
            context.push('/import');
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: col.surface,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: col.ink, width: 2),
              boxShadow: col.cardShadow,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'import a puzzle',
                        style: AppTypography.body.copyWith(
                          color: col.ink,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'from a newspaper or another app',
                        style: AppTypography.labelSmall
                            .copyWith(color: col.ink4, fontSize: 9),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: col.ink4, size: 18),
              ],
            ),
          ),
        ),
        Row(
          children: [
            for (int i = 0; i < Difficulty.deep.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: _DeepCard(
                  difficulty: Difficulty.deep[i],
                  bestTimeSecs: state.bestTimes[Difficulty.deep[i].name],
                  // Explains before it plays. "fish" means nothing until
                  // somebody shows you one, and this used to spend several
                  // seconds building a puzzle that needed a technique the
                  // player had no way to look up from here.
                  onTap: () {
                    HapticFeedback.lightImpact();
                    context.push('/learn/tier/${Difficulty.deep[i].maxTier.name}');
                  },
                ).animate(delay: (160 + i * 40).ms).fadeIn(duration: 200.ms).slideY(
                    begin: 0.04, end: 0, duration: 200.ms, curve: Curves.easeOut),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Returns true when it is safe to throw away the slot [isDaily] names.
  ///
  /// Only that slot: starting a quick game no longer asks about the daily
  /// sitting half-finished in the other one, because it is not going to
  /// touch it.
  Future<bool> _confirmDiscardIfNeeded(
    BuildContext context, {
    required bool isDaily,
  }) =>
      confirmDiscard(
        context,
        context.read<HomeCubit>().state.saved.slotFor(isDaily: isDaily),
      );

  Future<void> _startGame(BuildContext context, Difficulty difficulty) async {
    HapticFeedback.lightImpact();
    if (!await _confirmDiscardIfNeeded(context, isDaily: false)) return;
    if (!context.mounted) return;
    Log.difficultySelected(difficulty: difficulty.name);
    await context.read<SavedGameRepository>().deleteSavedGame(isDaily: false);
    if (!context.mounted) return;
    context.push('/game/${difficulty.name}');
  }

  Future<void> _startDaily(BuildContext context) async {
    HapticFeedback.lightImpact();

    // If the in-progress game IS today's daily, tapping the daily card means
    // "carry on", not "throw it away". Prompting to discard here would be
    // asking the player to destroy the thing they just asked for.
    final saved = context.read<HomeCubit>().state.saved.daily;
    if (saved != null && saved.puzzleId == dailyPuzzleId()) {
      context.push('/game/resume', extra: saved);
      return;
    }

    if (!await _confirmDiscardIfNeeded(context, isDaily: true)) return;
    if (!context.mounted) return;
    final state = context.read<HomeCubit>().state;
    Log.dailyPuzzleTapped(alreadyCompleted: state.dailyCompleted);
    await context.read<SavedGameRepository>().deleteSavedGame(isDaily: true);
    if (!context.mounted) return;
    context.push('/game/daily');
  }

  /// The way to the days you missed.
  ///
  /// Under the daily card rather than in the deeper shelf, because it is the
  /// same product as the card above it — one line, right-aligned, quiet
  /// enough that it does not compete with today's puzzle for the tap.
  Widget _buildArchiveLink(BuildContext context) {
    final col = context.appColors;
    return Align(
      alignment: Alignment.centerRight,
      child: Tappable(
        label: 'past dailies',
        hint: 'play a daily you missed',
        onTap: () {
          HapticFeedback.lightImpact();
          Log.archiveOpened();
          context.push('/daily');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('past dailies',
                  style: AppTypography.labelSmall
                      .copyWith(color: col.ink3, fontSize: 11)),
              const SizedBox(width: 3),
              Icon(Icons.chevron_right, size: 14, color: col.ink3),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl),
        child: Text(
          'just sudoku.',
          style: AppTypography.labelSmall.copyWith(
            color: context.appColors.textDisabled,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

/// A deep-tier card. Deliberately quieter than the four main cards — outline
/// rather than fill — so the shelf reads as somewhere you go on purpose
/// rather than a fifth and sixth option of equal weight.
class _DeepCard extends StatelessWidget {
  const _DeepCard({
    required this.difficulty,
    required this.onTap,
    this.bestTimeSecs,
  });

  final Difficulty difficulty;
  final int? bestTimeSecs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final best =
        bestTimeSecs != null && bestTimeSecs != 0 ? clockTime(bestTimeSecs!) : '—';

    return Tappable(
      label: '${difficulty.name}. ${difficulty.maxTier.blurb}. '
          '${best == '—' ? 'no best time yet' : 'best ${spokenDuration(bestTimeSecs!)}'}',
      hint: 'find out what this is, then play one',
      onTap: onTap,
      child: Container(
        // A little taller than the four classic cards: these carry a short
        // description rather than a two-word label. Kept short deliberately —
        // a clipped explanation is worse than none, and the full one is a tap
        // away on the tier page.
        height: 84,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: col.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              difficulty.name,
              style: AppTypography.body.copyWith(
                color: col.ink,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    // A shape to picture, not a list of words to look up.
                    // "x-wing, swordfish" is more jargon to someone who does
                    // not know what a fish is.
                    difficulty.maxTier.blurb,
                    style: AppTypography.labelSmall.copyWith(
                      color: col.ink4,
                      fontSize: 9,
                      height: 1.3,
                    ),
                    maxLines: 2,
                  ),
                ),
                Text(
                  best,
                  style: AppTypography.number.copyWith(
                    color: col.ink4,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DifficultyCard extends StatelessWidget {
  final int index;
  final Difficulty difficulty;
  final bool isRecommended;
  final int? bestTimeSecs;
  final VoidCallback onTap;

  const _DifficultyCard({
    required this.index,
    required this.difficulty,
    required this.isRecommended,
    required this.onTap,
    this.bestTimeSecs,
  });

  String? _formatTime(int? secs) {
    if (secs == null || secs == 0) return null;
    return clockTime(secs);
  }

  @override
  Widget build(BuildContext context) {
    final col = context.appColors;
    final diffColor = col.difficultyColor(difficulty.name);
    final num = (index + 1).toString().padLeft(2, '0');
    final bestTime = _formatTime(bestTimeSecs);
    // What the puzzle will ask of you, not how many clues it starts with.
    // The clue count was a hardcoded second copy of Difficulty.clueRange and
    // would drift silently; the ceiling is both derived and more useful.
    // hard and expert share a ceiling on purpose — they are the same kind of
    // puzzle, separated by how much is dug out.
    final ceiling = difficulty == Difficulty.expert
        ? 'fewest clues'
        : difficulty.maxTier.ceilingShort;

    return Tappable(
      label: [
        difficulty.name,
        ceiling,
        if (isRecommended) 'recommended for you',
        bestTime == null
            ? 'no best time yet'
            : 'best ${spokenDuration(bestTimeSecs!)}',
      ].join('. '),
      hint: 'start a new ${difficulty.name} puzzle',
      onTap: onTap,
      child: Container(
        height: 100,
        decoration: BoxDecoration(
          color: diffColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: col.ink, width: 2),
          boxShadow: col.cardShadow,
        ),
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Faded large number watermark
            Positioned(
              bottom: -10,
              right: 4,
              child: Text(
                num,
                style: AppTypography.number.copyWith(
                  fontSize: 60,
                  fontWeight: FontWeight.w700,
                  color: col.ink.withValues(alpha: 0.08),
                  height: 1,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Faded number label top-left
                  Text(
                    num,
                    style: AppTypography.number.copyWith(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: col.ink.withValues(alpha: 0.35),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    difficulty.name,
                    style: AppTypography.body.copyWith(
                      color: col.ink,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      // Flexible, because "up to intersections" is nineteen
                      // characters in a half-width card and the system text
                      // size can double it. The best time is four characters
                      // and keeps its place; the promise is the part that
                      // gives.
                      // Expanded rather than a Spacer after a plain Text:
                      // the best time still sits on the right edge, and the
                      // promise now has somewhere to give.
                      Expanded(
                        child: Text(
                          ceiling,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.labelSmall.copyWith(
                            color: col.ink.withValues(alpha: 0.55),
                            fontSize: 9,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        bestTime ?? '—',
                        style: AppTypography.number.copyWith(
                          color: col.ink.withValues(alpha: 0.55),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // "★ FOR YOU" sticker
            if (isRecommended)
              Positioned(
                top: -4,
                right: 10,
                child: Transform.rotate(
                  angle: 0.05,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: col.accent,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: col.ink, width: 1.5),
                      boxShadow: [BoxShadow(color: col.ink, offset: const Offset(1, 1), blurRadius: 0)],
                    ),
                    child: Text(
                      '★ FOR YOU',
                      style: AppTypography.labelSmall.copyWith(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

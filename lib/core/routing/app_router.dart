import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/logger.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/repositories/repositories.dart';
import '../../engine/sudoku_board.dart';
import '../../engine/sudoku_solver.dart';
import '../../engine/deduction/deduction.dart';
import '../../features/complete/complete_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/import/import_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/learn/learn_cubit.dart';
import '../../features/learn/learn_screen.dart';
import '../../features/learn/technique_detail_screen.dart';
import '../../features/learn/tier_detail_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/stats_screen.dart';
import 'route_args.dart';

CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, _, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

GoRouter? _router;

/// Drops the cached router so the next [appRouter] read builds a fresh one.
///
/// The router is a lazily-cached global, so it retains navigation state across
/// widget tests: a test that ends on /home leaves the next test's `App()`
/// mounted at /home instead of replaying the splash. Call this in `setUp`.
@visibleForTesting
void resetAppRouter() {
  _router?.dispose();
  _router = null;
}

Technique? _techniqueNamed(String? name) =>
    Technique.values.where((t) => t.name == name).firstOrNull;

/// Both learn screens read the same mastery profile, and the detail screen is
/// pushed on top of the list, so the cubit is provided per route rather than
/// once around both — a shared instance would keep the list's data alive
/// behind a detail screen that has just changed it.
class _LearnHost extends StatelessWidget {
  const _LearnHost({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (ctx) => LearnCubit(ctx.read<MasteryRepository>()),
      child: child,
    );
  }
}

GoRouter get appRouter => _router ??= GoRouter(
  initialLocation: '/',
  observers: [
    if (Log.analytics != null)
      FirebaseAnalyticsObserver(analytics: Log.analytics!),
  ],
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: '/onboarding',
      pageBuilder: (_, _) => _fadePage(const OnboardingScreen()),
    ),
    GoRoute(
      path: '/home',
      pageBuilder: (_, _) => _fadePage(const HomeScreen()),
    ),
    GoRoute(
      path: '/stats',
      pageBuilder: (_, _) => _fadePage(const StatsScreen()),
    ),
    GoRoute(
      path: '/settings',
      pageBuilder: (_, _) => _fadePage(const SettingsScreen()),
    ),
    GoRoute(
      path: '/game/resume',
      redirect: (_, state) => state.extra is! SavedGame ? '/home' : null,
      pageBuilder: (_, state) {
        final saved = state.extra! as SavedGame;
        return _fadePage(GameScreen(
          difficulty: Difficulty.medium,
          resumeFrom: saved,
        ));
      },
    ),
    GoRoute(
      path: '/game/daily',
      pageBuilder: (_, _) => _fadePage(const GameScreen(
        difficulty: Difficulty.hard,
        isDaily: true,
      )),
    ),
    GoRoute(
      path: '/game/import',
      // Declared above /game/:difficulty on purpose. That wildcard happily
      // matches "import" as a difficulty name, falls back to medium, and
      // generates a random puzzle — which is exactly what it did until this
      // moved.
      //
      // The grid and its verified answer are handed over rather than
      // recomputed: the import screen has already paid for the exponential
      // uniqueness check and doing it twice would repeat a multi-second wait.
      redirect: (_, state) =>
          state.extra is! ({SudokuBoard puzzle, SudokuBoard solution})
              ? '/import'
              : null,
      pageBuilder: (_, state) {
        final args =
            state.extra! as ({SudokuBoard puzzle, SudokuBoard solution});
        return _fadePage(GameScreen(
          difficulty: Difficulty.medium,
          importedPuzzle: args.puzzle,
          importedSolution: args.solution,
        ));
      },
    ),
    GoRoute(
      path: '/game/:difficulty',
      pageBuilder: (_, state) {
        final difficultyParam = state.pathParameters['difficulty'] ?? 'medium';
        final difficulty = Difficulty.fromName(difficultyParam);
        return _fadePage(GameScreen(difficulty: difficulty));
      },
    ),
    GoRoute(
      path: '/import',
      pageBuilder: (_, _) => _fadePage(const ImportScreen()),
    ),
    GoRoute(
      path: '/learn',
      pageBuilder: (_, _) => _fadePage(const _LearnHost(child: LearnScreen())),
    ),
    GoRoute(
      path: '/learn/tier/:tier',
      pageBuilder: (_, state) {
        final name = state.pathParameters['tier'];
        final tier = TechniqueTier.values
            .where((t) => t.name == name)
            .firstOrNull;
        if (tier == null) {
          return _fadePage(const _LearnHost(child: LearnScreen()));
        }
        // Only the deep tiers are playable in their own right; the rest are
        // reference pages reached from the library.
        final difficulty = Difficulty.deep
            .where((d) => d.maxTier == tier)
            .firstOrNull;
        return _fadePage(_LearnHost(
          child: TierDetailScreen(tier: tier, difficulty: difficulty),
        ));
      },
    ),
    GoRoute(
      path: '/learn/:technique',
      pageBuilder: (_, state) {
        final technique = _techniqueNamed(state.pathParameters['technique']);
        if (technique == null) {
          return _fadePage(const _LearnHost(child: LearnScreen()));
        }
        return _fadePage(
          _LearnHost(child: TechniqueDetailScreen(technique: technique)),
        );
      },
    ),
    GoRoute(
      path: '/train/:technique',
      pageBuilder: (_, state) {
        final technique = _techniqueNamed(state.pathParameters['technique']);
        // An unknown or undrillable name lands back on the library rather
        // than on a screen that can only fail.
        if (technique == null || !technique.isDrillable) {
          return _fadePage(const _LearnHost(child: LearnScreen()));
        }
        return _fadePage(GameScreen(
          difficulty: Difficulty.medium,
          drillTechnique: technique,
        ));
      },
    ),
    GoRoute(
      path: '/complete',
      redirect: (_, state) => state.extra is! CompleteRouteArgs ? '/home' : null,
      pageBuilder: (_, state) {
        final args = state.extra! as CompleteRouteArgs;
        return _fadePage(CompleteScreen(args: args));
      },
    ),
  ],
);

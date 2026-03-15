import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/storage/app_database.dart';
import '../../engine/sudoku_solver.dart';
import '../../features/complete/complete_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/stats_screen.dart';

CustomTransitionPage<void> _fadePage(Widget child) {
  return CustomTransitionPage(
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    transitionsBuilder: (_, animation, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
      child: child,
    ),
  );
}

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const SplashScreen(),
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
      path: '/game/:difficulty',
      pageBuilder: (_, state) {
        final difficultyParam = state.pathParameters['difficulty'] ?? 'medium';
        final difficulty = Difficulty.values.firstWhere(
          (d) => d.name == difficultyParam,
          orElse: () => Difficulty.medium,
        );
        return _fadePage(GameScreen(difficulty: difficulty));
      },
    ),
    GoRoute(
      path: '/complete',
      redirect: (_, state) => state.extra == null ? '/home' : null,
      pageBuilder: (_, state) {
        final extra = state.extra! as Map<String, dynamic>;
        return _fadePage(CompleteScreen(
          qualityScore: extra['qualityScore'] as double,
          timeSeconds: extra['timeSeconds'] as int,
          hintsUsed: extra['hintsUsed'] as int,
          mistakes: extra['mistakes'] as int,
          difficulty: extra['difficulty'] as String,
          isDaily: extra['isDaily'] as bool,
          solveTimes: extra['solveTimes'] as List<int>,
        ));
      },
    ),
  ],
);

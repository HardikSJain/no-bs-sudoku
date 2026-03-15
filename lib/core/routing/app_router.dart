import 'package:go_router/go_router.dart';

import '../../engine/sudoku_solver.dart';
import '../../features/complete/complete_screen.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/settings/settings_screen.dart';
import '../../features/splash/splash_screen.dart';
import '../../features/stats/stats_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (_, _) => const SplashScreen(),
    ),
    GoRoute(
      path: '/home',
      builder: (_, _) => const HomeScreen(),
    ),
    GoRoute(
      path: '/stats',
      builder: (_, _) => const StatsScreen(),
    ),
    GoRoute(
      path: '/settings',
      builder: (_, _) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/game/daily',
      builder: (_, _) => const GameScreen(
        difficulty: Difficulty.hard,
        isDaily: true,
      ),
    ),
    GoRoute(
      path: '/game/:difficulty',
      builder: (_, state) {
        final difficultyParam = state.pathParameters['difficulty'] ?? 'medium';
        final difficulty = Difficulty.values.firstWhere(
          (d) => d.name == difficultyParam,
          orElse: () => Difficulty.medium,
        );
        return GameScreen(difficulty: difficulty);
      },
    ),
    GoRoute(
      path: '/complete',
      redirect: (_, state) => state.extra == null ? '/home' : null,
      builder: (_, state) {
        final extra = state.extra! as Map<String, dynamic>;
        return CompleteScreen(
          qualityScore: extra['qualityScore'] as double,
          timeSeconds: extra['timeSeconds'] as int,
          hintsUsed: extra['hintsUsed'] as int,
          mistakes: extra['mistakes'] as int,
          difficulty: extra['difficulty'] as String,
          isDaily: extra['isDaily'] as bool,
          solveTimes: extra['solveTimes'] as List<int>,
        );
      },
    ),
  ],
);

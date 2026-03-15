import 'package:go_router/go_router.dart';

import '../../engine/sudoku_solver.dart';
import '../../features/game/game_screen.dart';
import '../../features/home/home_screen.dart';
import '../../features/splash/splash_screen.dart';

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
  ],
);

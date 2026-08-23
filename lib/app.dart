import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/a11y/tappable.dart';
import 'core/routing/app_router.dart';
import 'core/storage/repositories/repositories.dart';
import 'core/theme/app_theme.dart';

class App extends StatelessWidget {
  const App({super.key, required this.repositories});

  final Repositories repositories;

  @override
  Widget build(BuildContext context) {
    // Provided individually rather than as the bundle so each consumer
    // declares the one repository it needs.
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider.value(value: repositories.records),
        RepositoryProvider.value(value: repositories.profiles),
        RepositoryProvider.value(value: repositories.preferences),
        RepositoryProvider.value(value: repositories.savedGames),
        RepositoryProvider.value(value: repositories.mastery),
        // GameCubit needs all four; documented on its constructor.
        RepositoryProvider.value(value: repositories),
      ],
      // One theme, so no cubit and no rebuild-on-change plumbing above the
      // router.
      child: MaterialApp.router(
        title: 'no bs sudoku',
        debugShowCheckedModeBanner: false,
        theme: appTheme(),
        routerConfig: appRouter,
        // The text-size policy, applied once for the whole app rather than
        // screen by screen. Above 2x the layouts stop being layouts — a
        // two-line stat label pushes the card it sits in off the screen — and
        // the honest thing is to cap it at the largest size everything is
        // actually tested at. The board clamps harder still, at its own
        // widget, because its cells cannot grow.
        builder: TextScale.applyContentPolicy,
      ),
    );
  }
}

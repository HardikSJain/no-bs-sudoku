import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
      ),
    );
  }
}

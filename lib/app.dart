import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routing/app_router.dart';
import 'core/storage/repositories/repositories.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

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
        // GameCubit needs all four; documented on its constructor.
        RepositoryProvider.value(value: repositories),
      ],
      child: BlocProvider(
        create: (ctx) => ThemeCubit(ctx.read<PreferencesRepository>()),
        child: BlocBuilder<ThemeCubit, String>(
          builder: (context, theme) {
            return MaterialApp.router(
              title: 'no bs sudoku',
              debugShowCheckedModeBanner: false,
              theme: appTheme(theme: theme),
              routerConfig: appRouter,
            );
          },
        ),
      ),
    );
  }
}

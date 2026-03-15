import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/routing/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => ThemeCubit(),
      child: BlocBuilder<ThemeCubit, String>(
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'no bs sudoku',
            debugShowCheckedModeBanner: false,
            theme: appTheme(isAmoled: themeMode == 'amoled'),
            routerConfig: appRouter,
          );
        },
      ),
    );
  }
}

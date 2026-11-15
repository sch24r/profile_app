import 'package:flutter/material.dart';

import 'core/router.dart';
import 'core/theme_controller.dart';
import 'theme/app_theme.dart';
import 'theme/motion.dart';

/// Root widget: provides the [ThemeController] and configures [MaterialApp]
/// (named routes = section paths, P1 transitions, clamped text scaling).
class PortfolioApp extends StatelessWidget {
  const PortfolioApp({super.key, required this.theme});

  final ThemeController theme;

  @override
  Widget build(BuildContext context) {
    return ThemeScope(
      controller: theme,
      child: ValueListenableBuilder<ThemeMode>(
        valueListenable: theme,
        builder: (context, mode, _) => MaterialApp(
          title: 'Marchello Putra Ramadhan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: mode,
          themeAnimationDuration: Motion.themeSwitch,
          color: const Color(0xFF2A0E57),
          initialRoute:
              WidgetsBinding.instance.platformDispatcher.defaultRouteName,
          onGenerateRoute: AppNav.onGenerateRoute,
          onGenerateInitialRoutes: AppNav.onGenerateInitialRoutes,
          navigatorObservers: [AppNav.observer],
          builder: (context, child) => MediaQuery.withClampedTextScaling(
            maxScaleFactor: 1.3,
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

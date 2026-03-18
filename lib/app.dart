import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/constants/app_strings.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'presentation/providers/theme_providers.dart';

class PlanerApp extends ConsumerWidget {
  const PlanerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(accentColor),
      darkTheme: AppTheme.dark(accentColor),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      routerConfig: appRouter,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('ru'),
      ],
      locale: const Locale('ru'),
    );
  }
}

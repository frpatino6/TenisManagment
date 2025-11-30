import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/app_config.dart';

/// Widget principal de la aplicación
///
/// Este widget es compartido entre todos los ambientes (dev, prod)
/// La configuración específica se establece en los entrypoints (main_dev.dart, main_prod.dart)
class TennisManagementApp extends ConsumerWidget {
  const TennisManagementApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode.themeMode,
      routerConfig: router,
      showPerformanceOverlay: AppConfig.showPerformanceOverlay,
    );
  }
}

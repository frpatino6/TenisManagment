import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/app_config.dart';
import 'core/providers/tenant_provider.dart';

/// Widget principal de la aplicación
///
/// Este widget es compartido entre todos los ambientes (dev, prod)
/// La configuración específica se establece en los entrypoints (main_dev.dart, main_prod.dart)
class TennisManagementApp extends ConsumerStatefulWidget {
  const TennisManagementApp({super.key});

  @override
  ConsumerState<TennisManagementApp> createState() =>
      _TennisManagementAppState();
}

class _TennisManagementAppState extends ConsumerState<TennisManagementApp> {
  @override
  void initState() {
    super.initState();
    // Initialize tenant service and load saved tenant
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // First initialize the service
      final service = ref.read(tenantServiceProvider);
      await service.initialize();
      // Then load tenant through notifier
      await ref.read(tenantNotifierProvider.notifier).loadTenant();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(
      themeProvider.select((theme) => theme.themeMode),
    );

    return MaterialApp.router(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: router,
      showPerformanceOverlay: AppConfig.showPerformanceOverlay,
    );
  }
}

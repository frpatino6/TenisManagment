import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'core/config/app_config.dart';
import 'core/constants/timeouts.dart';
import 'core/providers/tenant_provider.dart';
import 'features/student/presentation/providers/student_provider.dart';
import 'features/booking/presentation/providers/booking_provider.dart';
import 'core/utils/web_utils_stub.dart'
    if (dart.library.js_interop) 'core/utils/web_utils_web.dart';

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

class _TennisManagementAppState extends ConsumerState<TennisManagementApp>
    with WidgetsBindingObserver {
  void _handleFocusEvent() {
    // Refresh data when window regains focus (web only)
    // Add a small delay to ensure webhooks are processed
    Future.delayed(Timeouts.snackbarSuccess, () {
      if (mounted) {
        ref.invalidate(studentInfoProvider);
        ref.invalidate(myBookingsProvider);
      }
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // On web: also listen for window focus events (tab changes)
    if (kIsWeb) {
      WebUtils.addWindowFocusListener(_handleFocusEvent);
    }

    // Load tenant from backend on app startup
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Load tenant through notifier (service is stateless, no initialization needed)
      await ref.read(tenantNotifierProvider.notifier).loadTenant();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // On web: remove window focus listener
    if (kIsWeb) {
      WebUtils.removeWindowFocusListener(_handleFocusEvent);
    }
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // When app resumes (user returns from Wompi), refresh student data
    if (state == AppLifecycleState.resumed) {
      // Add delay to allow webhooks to process
      Future.delayed(Timeouts.snackbarSuccess, () {
        if (mounted) {
          ref.invalidate(studentInfoProvider);
          ref.invalidate(myBookingsProvider);
        }
      });
    }
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
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('es', 'ES'), // Spanish (Spain)
        Locale('en', 'US'), // English (United States)
      ],
      locale: const Locale('es', 'ES'),
    );
  }
}

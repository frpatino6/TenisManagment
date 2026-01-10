import 'package:flutter/foundation.dart';
import 'environment.dart';

/// Configuración global de la aplicación
///
/// Maneja todas las configuraciones específicas de cada ambiente:
/// - URLs del backend
/// - Configuraciones de Firebase
/// - Nombre de la aplicación
/// - Configuraciones de debugging
class AppConfig {
  static final AppConfig _instance = AppConfig._internal();
  factory AppConfig() => _instance;
  AppConfig._internal();

  /// Ambiente actual de la aplicación
  /// Se establece en el main.dart según el entrypoint (main_dev.dart o main_prod.dart)
  static Environment _environment = Environment.production;

  /// Establece el ambiente de la aplicación
  /// Debe llamarse al inicio en main() antes de inicializar Firebase
  static void setEnvironment(Environment env) {
    _environment = env;
  }

  /// Obtiene el ambiente actual
  static Environment get environment => _environment;

  /// Obtiene la URL base del backend según el ambiente
  static String get backendUrl {
    switch (_environment) {
      case Environment.development:
        if (defaultTargetPlatform == TargetPlatform.android) {
          return 'http://10.0.2.2:3000';
        } else {
          return 'http://localhost:3000';
        }

      case Environment.production:
        return 'https://tenismanagment.onrender.com';

      case Environment.uat:
        // TEMP: Apuntando a Prod mientras se resuelve el servicio UAT dedicado
        return 'https://tenismanagment.onrender.com';
    }
  }

  /// Obtiene la URL base de la API (backend + /api)
  static String get apiBaseUrl => '$backendUrl/api';

  /// Obtiene la URL base de autenticación
  static String get authBaseUrl => '$backendUrl/api/auth';

  /// Nombre de la aplicación según el ambiente
  static String get appName {
    switch (_environment) {
      case Environment.development:
        return 'Tennis DEV';
      case Environment.production:
        return 'Tennis Management';
      case Environment.uat:
        return 'Tennis UAT';
    }
  }

  /// Sufijo del package (para Android)
  static String get packageSuffix {
    switch (_environment) {
      case Environment.development:
        return '.dev';
      case Environment.production:
        return '';
      case Environment.uat:
        return '.uat';
    }
  }

  /// Package name completo
  static String get packageName =>
      'com.tennismanagement.tennis_management$packageSuffix';

  /// Habilita logs de debug (solo en desarrollo)
  static bool get enableDebugLogs => _environment.isDevelopment;

  /// Habilita logs de red (solo en desarrollo)
  static bool get enableNetworkLogs => _environment.isDevelopment;

  /// Habilita el banner de debug (solo en desarrollo)
  static bool get showDebugBanner => _environment.isDevelopment;

  /// Habilita performance overlay (solo en desarrollo)
  static bool get showPerformanceOverlay => false;

  /// Habilita analytics (solo en producción)
  static bool get enableAnalytics => _environment.isProduction;

  /// Habilita crash reporting (solo en producción)
  static bool get enableCrashReporting => _environment.isProduction;

  /// Timeout para requests HTTP (más largo en desarrollo para debugging)
  static Duration get httpTimeout {
    switch (_environment) {
      case Environment.development:
        return const Duration(seconds: 60);
      case Environment.production:
        return const Duration(seconds: 30);
      case Environment.uat:
        return const Duration(seconds: 30);
    }
  }

  /// Número máximo de reintentos para requests fallidos
  static int get maxRetries {
    switch (_environment) {
      case Environment.development:
        return 2;
      case Environment.production:
        return 3;
      case Environment.uat:
        return 3;
    }
  }
}

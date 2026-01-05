import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Niveles de logging
enum LogLevel { debug, info, warning, error, fatal }

/// Logger estructurado para la aplicación
///
/// Proporciona logging estructurado con diferentes niveles
/// y solo muestra logs en desarrollo por defecto.
class AppLogger {
  final String _tag;
  final bool _enabled;

  AppLogger._(this._tag, this._enabled);

  /// Crea un logger con el tag especificado
  factory AppLogger.tag(String tag) {
    return AppLogger._(tag, AppConfig.enableDebugLogs);
  }

  /// Crea un logger para una clase
  factory AppLogger.forClass(Type classType) {
    return AppLogger._(classType.toString(), AppConfig.enableDebugLogs);
  }

  /// Log de debug (solo en desarrollo)
  void debug(String message, [Map<String, dynamic>? context]) {
    if (!_enabled) return;
    _log(LogLevel.debug, message, context);
  }

  /// Log informativo
  void info(String message, [Map<String, dynamic>? context]) {
    if (!_enabled) return;
    _log(LogLevel.info, message, context);
  }

  /// Log de advertencia
  void warning(String message, [Map<String, dynamic>? context]) {
    if (!_enabled) return;
    _log(LogLevel.warning, message, context);
  }

  /// Log de error
  void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    if (!_enabled) return;
    _log(LogLevel.error, message, {
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      ...?context,
    });
  }

  /// Log fatal (siempre se muestra)
  void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, dynamic>? context,
  }) {
    _log(LogLevel.fatal, message, {
      if (error != null) 'error': error.toString(),
      if (stackTrace != null) 'stackTrace': stackTrace.toString(),
      ...?context,
    });
  }

  void _log(LogLevel level, String message, Map<String, dynamic>? context) {
    final timestamp = DateTime.now().toIso8601String();
    final levelStr = level.name.toUpperCase().padRight(7);
    final tagStr = _tag.padRight(30);

    final logMessage = '[$timestamp] $levelStr | $tagStr | $message';

    if (context != null && context.isNotEmpty) {
      final contextStr = context.entries
          .map((e) => '${e.key}: ${e.value}')
          .join(', ');
      debugPrint('$logMessage | Context: $contextStr');
    } else {
      debugPrint(logMessage);
    }

    // En producción, los errores fatales deberían enviarse a un servicio de crash reporting
    if (level == LogLevel.fatal && AppConfig.enableCrashReporting) {
      // Aquí se podría integrar con Firebase Crashlytics, Sentry, etc.
      // TODO: TEN-111 - Integrar con servicio de crash reporting
    }
  }
}

/// Extension para facilitar el uso del logger en clases
extension LoggerExtension on Object {
  AppLogger get logger => AppLogger.forClass(runtimeType);
}

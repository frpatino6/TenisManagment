import 'package:flutter/foundation.dart';
import '../config/app_config.dart';

/// Logging levels
enum LogLevel { debug, info, warning, error, fatal }

/// Structured logger for the application
///
/// Provides structured logging with different levels
/// and only shows logs in development by default.
class AppLogger {
  final String _tag;
  final bool _enabled;

  AppLogger._(this._tag, this._enabled);

  /// Creates a logger with the specified tag
  factory AppLogger.tag(String tag) {
    return AppLogger._(tag, AppConfig.enableDebugLogs);
  }

  /// Creates a logger for a class
  factory AppLogger.forClass(Type classType) {
    return AppLogger._(classType.toString(), AppConfig.enableDebugLogs);
  }

  /// Debug log (only in development)
  void debug(String message, [Map<String, dynamic>? context]) {
    if (!_enabled) return;
    _log(LogLevel.debug, message, context);
  }

  /// Info log
  void info(String message, [Map<String, dynamic>? context]) {
    if (!_enabled) return;
    _log(LogLevel.info, message, context);
  }

  /// Warning log
  void warning(String message, [Map<String, dynamic>? context]) {
    if (!_enabled) return;
    _log(LogLevel.warning, message, context);
  }

  /// Error log
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

  /// Fatal log (always shown)
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

    // In production, fatal errors should be sent to a crash reporting service
    if (level == LogLevel.fatal && AppConfig.enableCrashReporting) {
      // Here we could integrate with Firebase Crashlytics, Sentry, etc.
      // TODO: TEN-111 - Integrate with crash reporting service
    }
  }
}

/// Extension to facilitate logger usage in classes
extension LoggerExtension on Object {
  AppLogger get logger => AppLogger.forClass(runtimeType);
}

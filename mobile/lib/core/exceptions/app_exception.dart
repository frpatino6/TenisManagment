/// Base exception class for all application exceptions
/// Provides consistent error handling across the application
abstract class AppException implements Exception {
  final String message;
  final String? code;
  final dynamic originalError;
  final StackTrace? stackTrace;

  const AppException(
    this.message, {
    this.code,
    this.originalError,
    this.stackTrace,
  });

  @override
  String toString() => message;

  /// Returns a user-friendly error message
  String get userMessage => message;

  /// Returns technical details for debugging
  Map<String, dynamic> toMap() => {
    'message': message,
    'code': code,
    'type': runtimeType.toString(),
    if (originalError != null) 'originalError': originalError.toString(),
  };
}

import 'app_exception.dart';
import '../constants/error_messages.dart';

/// Exception thrown when network operations fail
class NetworkException extends AppException {
  const NetworkException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory NetworkException.timeout({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message ?? ErrorMessages.networkTimeout,
      code: 'TIMEOUT',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkException.noConnection({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message ?? ErrorMessages.noConnection,
      code: 'NO_CONNECTION',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory NetworkException.serverError({
    String? message,
    int? statusCode,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return NetworkException(
      message ??
          (statusCode != null
              ? ErrorMessages.serverErrorWithCode(statusCode)
              : ErrorMessages.serverError),
      code: 'SERVER_ERROR_${statusCode ?? 'UNKNOWN'}',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}

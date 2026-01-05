import 'app_exception.dart';
import '../constants/error_messages.dart';

/// Exception thrown when authentication operations fail
class AuthException extends AppException {
  const AuthException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory AuthException.notAuthenticated({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message ?? ErrorMessages.notAuthenticated,
      code: 'NOT_AUTHENTICATED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AuthException.invalidCredentials({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message ?? ErrorMessages.invalidCredentials,
      code: 'INVALID_CREDENTIALS',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AuthException.tokenExpired({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message ?? ErrorMessages.tokenExpired,
      code: 'TOKEN_EXPIRED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AuthException.userNotFound({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message ?? ErrorMessages.userNotFound,
      code: 'USER_NOT_FOUND',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory AuthException.emailAlreadyExists({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return AuthException(
      message ?? ErrorMessages.emailAlreadyExists,
      code: 'EMAIL_ALREADY_EXISTS',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}

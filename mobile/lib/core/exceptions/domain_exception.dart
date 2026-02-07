import 'app_exception.dart';
import '../constants/error_messages.dart';

/// Exception thrown when business logic rules are violated
class DomainException extends AppException {
  const DomainException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory DomainException.notFound({
    required String resource,
    String? id,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DomainException(
      id != null
          ? ErrorMessages.resourceNotFoundWithId(resource, id)
          : ErrorMessages.resourceNotFoundGeneric(resource),
      code: 'NOT_FOUND',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DomainException.conflict({
    required String message,
    String? details,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DomainException(
      message,
      code: 'CONFLICT',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DomainException.unauthorized({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DomainException(
      message ?? ErrorMessages.unauthorized,
      code: 'UNAUTHORIZED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory DomainException.operationNotAllowed({
    required String operation,
    String? reason,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return DomainException(
      reason ?? ErrorMessages.operationNotAllowedDomain,
      code: 'OPERATION_NOT_ALLOWED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}

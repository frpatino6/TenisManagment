import 'app_exception.dart';
import '../constants/error_messages.dart';

/// Exception thrown when data validation fails
class ValidationException extends AppException {
  final Map<String, String>? fieldErrors;

  const ValidationException(
    super.message, {
    super.code,
    this.fieldErrors,
    super.originalError,
    super.stackTrace,
  });

  factory ValidationException.invalidField({
    required String field,
    required String reason,
    Map<String, String>? additionalErrors,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    final errors = <String, String>{
      field: reason,
      ...?additionalErrors,
    };
    return ValidationException(
      ErrorMessages.invalidFieldMessage(field, reason),
      code: 'INVALID_FIELD',
      fieldErrors: errors,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory ValidationException.missingRequiredField({
    required String field,
    Map<String, String>? additionalErrors,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    final errors = <String, String>{
      field: ErrorMessages.fieldRequired,
      ...?additionalErrors,
    };
    return ValidationException(
      ErrorMessages.missingRequiredField,
      code: 'MISSING_REQUIRED_FIELD',
      fieldErrors: errors,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}


import 'domain_exception.dart';
import '../constants/error_messages.dart';

/// Exception thrown when schedule operations fail
class ScheduleException extends DomainException {
  final String? conflictingTenantId;
  final String? conflictingTenantName;
  final List<dynamic>? warnings;

  const ScheduleException(
    super.message, {
    super.code,
    this.conflictingTenantId,
    this.conflictingTenantName,
    this.warnings,
    super.originalError,
    super.stackTrace,
  });

  factory ScheduleException.conflict({
    required String message,
    String? conflictingTenantId,
    String? conflictingTenantName,
    List<dynamic>? warnings,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return ScheduleException(
      message,
      code: 'SCHEDULE_CONFLICT',
      conflictingTenantId: conflictingTenantId,
      conflictingTenantName: conflictingTenantName,
      warnings: warnings,
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory ScheduleException.notFound({
    String? scheduleId,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return ScheduleException(
      scheduleId != null
          ? ErrorMessages.resourceNotFoundWithId('Horario', scheduleId)
          : ErrorMessages.scheduleNotFound,
      code: 'SCHEDULE_NOT_FOUND',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory ScheduleException.invalidTime({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return ScheduleException(
      message ?? 'El horario seleccionado no es válido.',
      code: 'INVALID_TIME',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}


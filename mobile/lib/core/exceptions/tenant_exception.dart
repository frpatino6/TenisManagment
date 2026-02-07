import 'domain_exception.dart';
import '../constants/error_messages.dart';

/// Exception thrown when tenant operations fail
class TenantException extends DomainException {
  const TenantException(
    super.message, {
    super.code,
    super.originalError,
    super.stackTrace,
  });

  factory TenantException.notFound({
    String? tenantId,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return TenantException(
      tenantId != null
          ? ErrorMessages.resourceNotFoundWithId('Centro', tenantId)
          : ErrorMessages.tenantNotFound,
      code: 'TENANT_NOT_FOUND',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory TenantException.notConfigured({
    String? message,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return TenantException(
      message ??
          'No hay un centro configurado. Por favor, selecciona un centro.',
      code: 'TENANT_NOT_CONFIGURED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }

  factory TenantException.alreadyJoined({
    String? tenantName,
    dynamic originalError,
    StackTrace? stackTrace,
  }) {
    return TenantException(
      tenantName != null
          ? 'Ya estás registrado en el centro "$tenantName"'
          : 'Ya estás registrado en este centro',
      code: 'TENANT_ALREADY_JOINED',
      originalError: originalError,
      stackTrace: stackTrace,
    );
  }
}

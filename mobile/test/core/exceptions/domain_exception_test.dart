import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/exceptions/domain_exception.dart';
import 'package:tennis_management/core/constants/error_messages.dart';

void main() {
  group('DomainException', () {
    group('notFound', () {
      test('should create exception with resource name', () {
        final exception = DomainException.notFound(resource: 'Profesor');
        expect(exception, isA<DomainException>());
        expect(exception.message, contains('Profesor'));
        expect(exception.code, equals('NOT_FOUND'));
      });

      test('should create exception with resource and id', () {
        final exception = DomainException.notFound(
          resource: 'Estudiante',
          id: '123',
        );
        expect(exception, isA<DomainException>());
        expect(exception.message, contains('Estudiante'));
        expect(exception.message, contains('123'));
        expect(exception.code, equals('NOT_FOUND'));
      });
    });

    group('conflict', () {
      test('should create exception with message', () {
        final exception = DomainException.conflict(
          message: ErrorMessages.conflict,
        );
        expect(exception, isA<DomainException>());
        expect(exception.message, equals(ErrorMessages.conflict));
        expect(exception.code, equals('CONFLICT'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Conflicto de datos';
        final exception = DomainException.conflict(message: customMessage);
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('CONFLICT'));
      });
    });

    group('unauthorized', () {
      test('should create exception with default message', () {
        final exception = DomainException.unauthorized();
        expect(exception, isA<DomainException>());
        expect(exception.message, equals(ErrorMessages.unauthorized));
        expect(exception.code, equals('UNAUTHORIZED'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'No autorizado';
        final exception = DomainException.unauthorized(message: customMessage);
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('UNAUTHORIZED'));
      });
    });

    group('operationNotAllowed', () {
      test('should create exception with operation and reason', () {
        final exception = DomainException.operationNotAllowed(
          operation: 'delete',
          reason: 'No permitido',
        );
        expect(exception, isA<DomainException>());
        expect(exception.message, equals('No permitido'));
        expect(exception.code, equals('OPERATION_NOT_ALLOWED'));
      });

      test('should create exception without reason (uses default)', () {
        final exception = DomainException.operationNotAllowed(
          operation: 'update',
        );
        expect(exception, isA<DomainException>());
        expect(
          exception.message,
          equals(ErrorMessages.operationNotAllowedDomain),
        );
        expect(exception.code, equals('OPERATION_NOT_ALLOWED'));
      });
    });

    group('constructor', () {
      test('should create exception with custom message and code', () {
        final exception = DomainException(
          'Custom domain error',
          code: 'CUSTOM_ERROR',
        );
        expect(exception.message, equals('Custom domain error'));
        expect(exception.code, equals('CUSTOM_ERROR'));
      });
    });
  });
}

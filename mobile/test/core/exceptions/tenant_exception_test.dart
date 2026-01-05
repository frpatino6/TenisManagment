import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/exceptions/tenant_exception.dart';
import 'package:tennis_management/core/constants/error_messages.dart';

void main() {
  group('TenantException', () {
    group('notFound', () {
      test('should create exception with correct message', () {
        final exception = TenantException.notFound();
        expect(exception, isA<TenantException>());
        expect(exception.message, equals(ErrorMessages.tenantNotFound));
        expect(exception.code, equals('TENANT_NOT_FOUND'));
      });
    });

    group('notConfigured', () {
      test('should create exception with default message', () {
        final exception = TenantException.notConfigured();
        expect(exception, isA<TenantException>());
        expect(exception.message, contains('centro configurado'));
        expect(exception.code, equals('TENANT_NOT_CONFIGURED'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Centro no configurado';
        final exception = TenantException.notConfigured(message: customMessage);
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('TENANT_NOT_CONFIGURED'));
      });
    });

    group('alreadyJoined', () {
      test('should create exception with default message', () {
        final exception = TenantException.alreadyJoined();
        expect(exception, isA<TenantException>());
        expect(exception.message, contains('Ya estás registrado'));
        expect(exception.code, equals('TENANT_ALREADY_JOINED'));
      });

      test('should create exception with tenant name', () {
        final exception = TenantException.alreadyJoined(tenantName: 'Centro A');
        expect(exception, isA<TenantException>());
        expect(exception.message, contains('Centro A'));
        expect(exception.code, equals('TENANT_ALREADY_JOINED'));
      });
    });

    group('constructor', () {
      test('should create exception with custom message and code', () {
        final exception = TenantException(
          'Custom tenant error',
          code: 'CUSTOM_ERROR',
        );
        expect(exception.message, equals('Custom tenant error'));
        expect(exception.code, equals('CUSTOM_ERROR'));
      });
    });
  });
}


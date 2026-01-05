import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/exceptions/validation_exception.dart';
import 'package:tennis_management/core/constants/error_messages.dart';

void main() {
  group('ValidationException', () {
    group('missingRequiredField', () {
      test('should create exception with correct message', () {
        final exception = ValidationException.missingRequiredField(field: 'email');
        expect(exception, isA<ValidationException>());
        expect(exception.message, equals(ErrorMessages.missingRequiredField));
        expect(exception.code, equals('MISSING_REQUIRED_FIELD'));
        expect(exception.fieldErrors, isNotNull);
        expect(exception.fieldErrors!['email'], equals(ErrorMessages.fieldRequired));
      });

      test('should include field name in fieldErrors', () {
        final exception = ValidationException.missingRequiredField(field: 'password');
        expect(exception.fieldErrors, isNotNull);
        expect(exception.fieldErrors!['password'], equals(ErrorMessages.fieldRequired));
      });
    });

    group('invalidField', () {
      test('should create exception with correct message', () {
        final exception = ValidationException.invalidField(
          field: 'email',
          reason: 'Formato inválido',
        );
        expect(exception, isA<ValidationException>());
        expect(exception.message, contains('email'));
        expect(exception.message, contains('Formato inválido'));
        expect(exception.code, equals('INVALID_FIELD'));
      });

      test('should include field name and reason in message', () {
        final exception = ValidationException.invalidField(
          field: 'age',
          reason: 'Debe ser mayor de 18',
        );
        expect(exception.message, contains('age'));
        expect(exception.message, contains('Debe ser mayor de 18'));
      });
    });

    group('constructor', () {
      test('should create exception with custom message and code', () {
        final exception = ValidationException(
          'Custom validation error',
          code: 'CUSTOM_ERROR',
        );
        expect(exception.message, equals('Custom validation error'));
        expect(exception.code, equals('CUSTOM_ERROR'));
      });

      test('should use default code when not provided', () {
        final exception = ValidationException('Error message');
        expect(exception.message, equals('Error message'));
        expect(exception.code, isNull); // Default code is null if not provided
      });
    });
  });
}


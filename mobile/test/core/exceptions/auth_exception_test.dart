import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/exceptions/auth_exception.dart';
import 'package:tennis_management/core/constants/error_messages.dart';

void main() {
  group('AuthException', () {
    group('notAuthenticated', () {
      test('should create exception with correct message', () {
        final exception = AuthException.notAuthenticated();
        expect(exception, isA<AuthException>());
        expect(exception.message, equals(ErrorMessages.notAuthenticated));
        expect(exception.code, equals('NOT_AUTHENTICATED'));
      });
    });

    group('invalidCredentials', () {
      test('should create exception with default message', () {
        final exception = AuthException.invalidCredentials();
        expect(exception, isA<AuthException>());
        expect(exception.message, equals(ErrorMessages.invalidCredentials));
        expect(exception.code, equals('INVALID_CREDENTIALS'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Credenciales incorrectas';
        final exception = AuthException.invalidCredentials(
          message: customMessage,
        );
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('INVALID_CREDENTIALS'));
      });
    });

    group('tokenExpired', () {
      test('should create exception with correct message', () {
        final exception = AuthException.tokenExpired();
        expect(exception, isA<AuthException>());
        expect(exception.message, equals(ErrorMessages.tokenExpired));
        expect(exception.code, equals('TOKEN_EXPIRED'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Token expirado';
        final exception = AuthException.tokenExpired(message: customMessage);
        expect(exception.message, equals(customMessage));
      });
    });

    group('userNotFound', () {
      test('should create exception with correct message', () {
        final exception = AuthException.userNotFound();
        expect(exception, isA<AuthException>());
        expect(exception.message, equals(ErrorMessages.userNotFound));
        expect(exception.code, equals('USER_NOT_FOUND'));
      });
    });

    group('emailAlreadyExists', () {
      test('should create exception with default message', () {
        final exception = AuthException.emailAlreadyExists();
        expect(exception, isA<AuthException>());
        expect(exception.message, equals(ErrorMessages.emailAlreadyExists));
        expect(exception.code, equals('EMAIL_ALREADY_EXISTS'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Email ya registrado';
        final exception = AuthException.emailAlreadyExists(
          message: customMessage,
        );
        expect(exception.message, equals(customMessage));
      });
    });

    group('constructor', () {
      test('should create exception with custom message and code', () {
        final exception = AuthException(
          'Custom auth error',
          code: 'CUSTOM_ERROR',
        );
        expect(exception.message, equals('Custom auth error'));
        expect(exception.code, equals('CUSTOM_ERROR'));
      });

      test('should use default code when not provided', () {
        final exception = AuthException('Error message');
        expect(exception.message, equals('Error message'));
        expect(exception.code, isNull); // Default code is null if not provided
      });
    });
  });
}

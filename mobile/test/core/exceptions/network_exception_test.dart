import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/exceptions/network_exception.dart';
import 'package:tennis_management/core/constants/error_messages.dart';

void main() {
  group('NetworkException', () {
    group('noConnection', () {
      test('should create exception with correct message', () {
        final exception = NetworkException.noConnection();
        expect(exception, isA<NetworkException>());
        expect(exception.message, equals(ErrorMessages.noConnection));
        expect(exception.code, equals('NO_CONNECTION'));
      });
    });

    group('timeout', () {
      test('should create exception with correct message', () {
        final exception = NetworkException.timeout();
        expect(exception, isA<NetworkException>());
        expect(exception.message, equals(ErrorMessages.networkTimeout));
        expect(exception.code, equals('TIMEOUT'));
      });
    });

    group('serverError', () {
      test('should create exception with default message', () {
        final exception = NetworkException.serverError();
        expect(exception, isA<NetworkException>());
        expect(exception.message, equals(ErrorMessages.serverError));
        expect(exception.code, equals('SERVER_ERROR_UNKNOWN'));
      });

      test('should create exception with custom message and status code', () {
        final customMessage = 'Error del servidor';
        final statusCode = 500;
        final exception = NetworkException.serverError(
          message: customMessage,
          statusCode: statusCode,
        );
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('SERVER_ERROR_500'));
      });
    });

    group('serverError with status code', () {
      test('should create exception with status code in code', () {
        final exception = NetworkException.serverError(statusCode: 404);
        expect(exception, isA<NetworkException>());
        expect(exception.code, equals('SERVER_ERROR_404'));
      });

      test('should create exception without status code', () {
        final exception = NetworkException.serverError();
        expect(exception, isA<NetworkException>());
        expect(exception.code, equals('SERVER_ERROR_UNKNOWN'));
      });
    });

    group('constructor', () {
      test('should create exception with custom message and code', () {
        final exception = NetworkException(
          'Custom network error',
          code: 'CUSTOM_ERROR',
        );
        expect(exception.message, equals('Custom network error'));
        expect(exception.code, equals('CUSTOM_ERROR'));
      });

      test('should use default code when not provided', () {
        final exception = NetworkException('Error message');
        expect(exception.message, equals('Error message'));
        expect(exception.code, isNull); // Default code is null if not provided
      });
    });
  });
}

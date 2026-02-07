import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/result/result.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';

void main() {
  group('Result', () {
    group('Success', () {
      test('should create success result', () {
        const result = Result.success(42);
        expect(result, isA<Success<int>>());
        expect(result.isSuccess, isTrue);
        expect(result.isFailure, isFalse);
        expect(result.valueOrNull, equals(42));
        expect(result.errorOrNull, isNull);
      });

      test('should return value with getOrThrow', () {
        const result = Result.success('test');
        expect(result.getOrThrow(), equals('test'));
      });

      test('should return value with getOrElse', () {
        const result = Result.success('test');
        expect(result.getOrElse('default'), equals('test'));
      });
    });

    group('Failure', () {
      test('should create failure result', () {
        final exception = AuthException.notAuthenticated();
        final result = Result<int>.failure(exception);
        expect(result, isA<Failure<int>>());
        expect(result.isSuccess, isFalse);
        expect(result.isFailure, isTrue);
        expect(result.valueOrNull, isNull);
        expect(result.errorOrNull, equals(exception));
      });

      test('should throw error with getOrThrow', () {
        final exception = NetworkException.timeout();
        final result = Result.failure(exception);
        expect(() => result.getOrThrow(), throwsA(equals(exception)));
      });

      test('should return default value with getOrElse', () {
        final exception = ValidationException.missingRequiredField(
          field: 'email',
        );
        final result = Result.failure(exception);
        expect(result.getOrElse('default'), equals('default'));
      });
    });

    group('map', () {
      test('should map success value', () {
        const result = Result.success(5);
        final mapped = result.map((value) => value * 2);
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, equals(10));
      });

      test('should preserve failure on map', () {
        final exception = AuthException.invalidCredentials();
        final result = Result.failure(exception);
        final mapped = result.map((value) => value * 2);
        expect(mapped.isFailure, isTrue);
        expect(mapped.errorOrNull, equals(exception));
      });
    });

    group('mapAsync', () {
      test('should map success value asynchronously', () async {
        const result = Result.success(5);
        final mapped = await result.mapAsync((value) async => value * 2);
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, equals(10));
      });

      test('should preserve failure on mapAsync', () async {
        final exception = NetworkException.noConnection();
        final result = Result.failure(exception);
        final mapped = await result.mapAsync((value) async => value * 2);
        expect(mapped.isFailure, isTrue);
        expect(mapped.errorOrNull, equals(exception));
      });
    });

    group('mapError', () {
      test('should map error', () {
        final exception = NetworkException.timeout();
        final result = Result.failure(exception);
        final mapped = result.mapError(
          (error) => NetworkException.serverError(message: 'Mapped error'),
        );
        expect(mapped.isFailure, isTrue);
        expect(mapped.errorOrNull?.message, contains('Mapped error'));
      });

      test('should preserve success on mapError', () {
        const result = Result.success(42);
        final mapped = result.mapError(
          (error) => NetworkException.serverError(),
        );
        expect(mapped.isSuccess, isTrue);
        expect(mapped.valueOrNull, equals(42));
      });
    });

    group('fold', () {
      test('should execute onSuccess for success', () {
        const result = Result.success(42);
        final value = result.fold(
          onSuccess: (value) => 'Success: $value',
          onFailure: (error) => 'Error: ${error.message}',
        );
        expect(value, equals('Success: 42'));
      });

      test('should execute onFailure for failure', () {
        final exception = AuthException.notAuthenticated();
        final result = Result.failure(exception);
        final value = result.fold(
          onSuccess: (value) => 'Success: $value',
          onFailure: (error) => 'Error: ${error.message}',
        );
        expect(value, contains('Error:'));
        expect(value, contains(exception.message));
      });
    });

    group('onSuccess', () {
      test('should execute action on success', () {
        const result = Result.success(42);
        var executed = false;
        result.onSuccess((value) {
          expect(value, equals(42));
          executed = true;
        });
        expect(executed, isTrue);
      });

      test('should not execute action on failure', () {
        final exception = NetworkException.timeout();
        final result = Result.failure(exception);
        var executed = false;
        result.onSuccess((value) {
          executed = true;
        });
        expect(executed, isFalse);
      });

      test('should return same result', () {
        const result = Result.success(42);
        final returned = result.onSuccess((value) {});
        expect(returned, equals(result));
      });
    });

    group('onFailure', () {
      test('should execute action on failure', () {
        final exception = ValidationException.missingRequiredField(
          field: 'email',
        );
        final result = Result.failure(exception);
        var executed = false;
        result.onFailure((error) {
          expect(error, equals(exception));
          executed = true;
        });
        expect(executed, isTrue);
      });

      test('should not execute action on success', () {
        const result = Result.success(42);
        var executed = false;
        result.onFailure((error) {
          executed = true;
        });
        expect(executed, isFalse);
      });

      test('should return same result', () {
        final exception = AuthException.invalidCredentials();
        final result = Result.failure(exception);
        final returned = result.onFailure((error) {});
        expect(returned, equals(result));
      });
    });
  });

  group('ResultExtension', () {
    test('should convert successful future to success result', () async {
      Future<int> future() async => 42;
      final result = await future.toResult();
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, equals(42));
    });

    test('should convert AppException to failure result', () async {
      Future<int> future() async {
        throw AuthException.notAuthenticated();
      }

      final result = await future.toResult();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<AuthException>());
    });

    test('should convert generic exception to NetworkException', () async {
      Future<int> future() async {
        throw Exception('Generic error');
      }

      final result = await future.toResult();
      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<NetworkException>());
      expect(result.errorOrNull?.message, contains('Generic error'));
    });
  });
}

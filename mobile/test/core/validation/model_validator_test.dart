import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/validation/model_validator.dart';
import 'package:tennis_management/core/exceptions/validation_exception.dart';

void main() {
  group('ModelValidator', () {
    group('validateNonEmpty', () {
      test('should not throw for valid non-empty string', () {
        expect(
          () => ModelValidator.validateNonEmpty('valid string', 'name'),
          returnsNormally,
        );
      });

      test('should return the same string when valid', () {
        final result = ModelValidator.validateNonEmpty('test', 'name');
        expect(result, equals('test'));
      });

      test('should throw AssertionError for empty string in debug mode', () {
        expect(
          () => ModelValidator.validateNonEmpty('', 'name'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw AssertionError with correct field name', () {
        expect(
          () => ModelValidator.validateNonEmpty('', 'userName'),
          throwsA(
            predicate<AssertionError>(
              (e) => e.message.toString().contains('userName'),
            ),
          ),
        );
      });
    });

    group('validateEmail', () {
      test('should not throw for valid email', () {
        expect(
          () => ModelValidator.validateEmail('test@example.com', 'email'),
          returnsNormally,
        );
      });

      test('should return the same email when valid', () {
        final result = ModelValidator.validateEmail(
          'test@example.com',
          'email',
        );
        expect(result, equals('test@example.com'));
      });

      test('should not throw for email with subdomain', () {
        expect(
          () => ModelValidator.validateEmail('user@mail.example.com', 'email'),
          returnsNormally,
        );
      });

      test('should throw AssertionError for email without @ in debug mode', () {
        expect(
          () => ModelValidator.validateEmail('invalidemail.com', 'email'),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
        'should throw AssertionError for email without domain in debug mode',
        () {
          expect(
            () => ModelValidator.validateEmail('invalid@', 'email'),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test(
        'should throw AssertionError for email without TLD in debug mode',
        () {
          expect(
            () => ModelValidator.validateEmail('invalid@domain', 'email'),
            throwsA(isA<AssertionError>()),
          );
        },
      );
    });

    group('validateNonNegative', () {
      test('should not throw for positive double', () {
        expect(
          () => ModelValidator.validateNonNegative(10.5, 'price'),
          returnsNormally,
        );
      });

      test('should return the same value when valid', () {
        final result = ModelValidator.validateNonNegative(10.5, 'price');
        expect(result, equals(10.5));
      });

      test('should not throw for zero', () {
        expect(
          () => ModelValidator.validateNonNegative(0.0, 'price'),
          returnsNormally,
        );
      });

      test('should throw AssertionError for negative double in debug mode', () {
        expect(
          () => ModelValidator.validateNonNegative(-5.0, 'price'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw ValidationException when value is below min', () {
        expect(
          () => ModelValidator.validateNonNegative(5.0, 'price', min: 10.0),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ValidationException when value is above max', () {
        expect(
          () => ModelValidator.validateNonNegative(100.0, 'price', max: 50.0),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should not throw when value is within min and max', () {
        expect(
          () => ModelValidator.validateNonNegative(
            25.0,
            'price',
            min: 10.0,
            max: 50.0,
          ),
          returnsNormally,
        );
      });
    });

    group('validateNonNegativeInt', () {
      test('should not throw for positive integer', () {
        expect(
          () => ModelValidator.validateNonNegativeInt(10, 'count'),
          returnsNormally,
        );
      });

      test('should return the same value when valid', () {
        final result = ModelValidator.validateNonNegativeInt(10, 'count');
        expect(result, equals(10));
      });

      test('should not throw for zero', () {
        expect(
          () => ModelValidator.validateNonNegativeInt(0, 'count'),
          returnsNormally,
        );
      });

      test(
        'should throw AssertionError for negative integer in debug mode',
        () {
          expect(
            () => ModelValidator.validateNonNegativeInt(-5, 'count'),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test('should throw ValidationException when value is below min', () {
        expect(
          () => ModelValidator.validateNonNegativeInt(5, 'count', min: 10),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ValidationException when value is above max', () {
        expect(
          () => ModelValidator.validateNonNegativeInt(100, 'count', max: 50),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('validateRating', () {
      test('should not throw for valid rating', () {
        expect(
          () => ModelValidator.validateRating(4.5, 'rating'),
          returnsNormally,
        );
      });

      test('should return the same value when valid', () {
        final result = ModelValidator.validateRating(4.5, 'rating');
        expect(result, equals(4.5));
      });

      test('should not throw for minimum rating (0.0)', () {
        expect(
          () => ModelValidator.validateRating(0.0, 'rating'),
          returnsNormally,
        );
      });

      test('should not throw for maximum rating (5.0)', () {
        expect(
          () => ModelValidator.validateRating(5.0, 'rating'),
          returnsNormally,
        );
      });

      test('should throw AssertionError for negative rating in debug mode', () {
        expect(
          () => ModelValidator.validateRating(-1.0, 'rating'),
          throwsA(isA<AssertionError>()),
        );
      });

      test(
        'should throw AssertionError for rating above 5.0 in debug mode',
        () {
          expect(
            () => ModelValidator.validateRating(6.0, 'rating'),
            throwsA(isA<AssertionError>()),
          );
        },
      );
    });

    group('validateTimeRange', () {
      test('should not throw for valid time range', () {
        final start = DateTime(2024, 1, 1, 10, 0);
        final end = DateTime(2024, 1, 1, 11, 0);
        expect(
          () => ModelValidator.validateTimeRange(start, end, 'schedule'),
          returnsNormally,
        );
      });

      test(
        'should throw AssertionError when end is not after start in debug mode',
        () {
          final start = DateTime(2024, 1, 1, 11, 0);
          final end = DateTime(2024, 1, 1, 10, 0);
          expect(
            () => ModelValidator.validateTimeRange(start, end, 'schedule'),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test(
        'should throw AssertionError when end equals start in debug mode',
        () {
          final time = DateTime(2024, 1, 1, 10, 0);
          expect(
            () => ModelValidator.validateTimeRange(time, time, 'schedule'),
            throwsA(isA<AssertionError>()),
          );
        },
      );

      test('should throw AssertionError with correct field name', () {
        final start = DateTime(2024, 1, 1, 11, 0);
        final end = DateTime(2024, 1, 1, 10, 0);
        expect(
          () => ModelValidator.validateTimeRange(start, end, 'bookingTime'),
          throwsA(
            predicate<AssertionError>(
              (e) => e.message.toString().contains('bookingTime'),
            ),
          ),
        );
      });
    });

    group('validatePrice', () {
      test('should not throw for valid price', () {
        expect(() => ModelValidator.validatePrice(50.0), returnsNormally);
      });

      test('should return the same value when valid', () {
        final result = ModelValidator.validatePrice(50.0);
        expect(result, equals(50.0));
      });

      test('should not throw for zero price', () {
        expect(() => ModelValidator.validatePrice(0.0), returnsNormally);
      });

      test('should throw AssertionError for negative price in debug mode', () {
        expect(
          () => ModelValidator.validatePrice(-10.0),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should throw ValidationException for price above max', () {
        expect(
          () => ModelValidator.validatePrice(2000000.0, max: 1000000.0),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('parseDouble', () {
      test('should parse valid double from num', () {
        final result = ModelValidator.parseDouble(10.5, 'price');
        expect(result, equals(10.5));
      });

      test('should parse valid double from int', () {
        final result = ModelValidator.parseDouble(10, 'price');
        expect(result, equals(10.0));
      });

      test('should use defaultValue when value is null', () {
        final result = ModelValidator.parseDouble(
          null,
          'price',
          defaultValue: 5.0,
        );
        expect(result, equals(5.0));
      });

      test('should throw AssertionError for negative value in debug mode', () {
        expect(
          () => ModelValidator.parseDouble(-10.0, 'price'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should respect min constraint', () {
        expect(
          () => ModelValidator.parseDouble(5.0, 'price', min: 10.0),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should respect max constraint', () {
        expect(
          () => ModelValidator.parseDouble(100.0, 'price', max: 50.0),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('parseInt', () {
      test('should parse valid int from num', () {
        final result = ModelValidator.parseInt(10, 'count');
        expect(result, equals(10));
      });

      test('should parse valid int from double', () {
        final result = ModelValidator.parseInt(10.5, 'count');
        expect(result, equals(10));
      });

      test('should use defaultValue when value is null', () {
        final result = ModelValidator.parseInt(null, 'count', defaultValue: 5);
        expect(result, equals(5));
      });

      test('should throw AssertionError for negative value in debug mode', () {
        expect(
          () => ModelValidator.parseInt(-10, 'count'),
          throwsA(isA<AssertionError>()),
        );
      });

      test('should respect min constraint', () {
        expect(
          () => ModelValidator.parseInt(5, 'count', min: 10),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should respect max constraint', () {
        expect(
          () => ModelValidator.parseInt(100, 'count', max: 50),
          throwsA(isA<ValidationException>()),
        );
      });
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/core/exceptions/schedule_exception.dart';
import 'package:tennis_management/core/constants/error_messages.dart';

void main() {
  group('ScheduleException', () {
    group('conflict', () {
      test('should create exception with message', () {
        final exception = ScheduleException.conflict(
          message: ErrorMessages.scheduleConflict,
        );
        expect(exception, isA<ScheduleException>());
        expect(exception.message, equals(ErrorMessages.scheduleConflict));
        expect(exception.code, equals('SCHEDULE_CONFLICT'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Conflicto de horarios';
        final exception = ScheduleException.conflict(message: customMessage);
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('SCHEDULE_CONFLICT'));
      });

      test('should include conflicting tenant information', () {
        final exception = ScheduleException.conflict(
          message: 'Conflicto',
          conflictingTenantId: 'tenant-123',
          conflictingTenantName: 'Centro A',
        );
        expect(exception.conflictingTenantId, equals('tenant-123'));
        expect(exception.conflictingTenantName, equals('Centro A'));
      });

      test('should include warnings', () {
        final warnings = ['Warning 1', 'Warning 2'];
        final exception = ScheduleException.conflict(
          message: 'Conflicto',
          warnings: warnings,
        );
        expect(exception.warnings, equals(warnings));
      });
    });

    group('notFound', () {
      test('should create exception with correct message', () {
        final exception = ScheduleException.notFound();
        expect(exception, isA<ScheduleException>());
        expect(exception.message, equals(ErrorMessages.scheduleNotFound));
        expect(exception.code, equals('SCHEDULE_NOT_FOUND'));
      });
    });

    group('invalidTime', () {
      test('should create exception with default message', () {
        final exception = ScheduleException.invalidTime();
        expect(exception, isA<ScheduleException>());
        expect(exception.message, contains('horario'));
        expect(exception.code, equals('INVALID_TIME'));
      });

      test('should create exception with custom message', () {
        final customMessage = 'Horario inválido';
        final exception = ScheduleException.invalidTime(message: customMessage);
        expect(exception.message, equals(customMessage));
        expect(exception.code, equals('INVALID_TIME'));
      });
    });

    group('constructor', () {
      test('should create exception with custom message and code', () {
        final exception = ScheduleException(
          'Custom schedule error',
          code: 'CUSTOM_ERROR',
        );
        expect(exception.message, equals('Custom schedule error'));
        expect(exception.code, equals('CUSTOM_ERROR'));
      });
    });
  });
}

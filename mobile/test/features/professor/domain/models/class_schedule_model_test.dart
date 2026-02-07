import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/professor/domain/models/class_schedule_model.dart';

void main() {
  group('ClassScheduleModel', () {
    final startTime = DateTime(2024, 1, 15, 10, 0).toUtc();
    final endTime = DateTime(2024, 1, 15, 11, 0).toUtc();

    final validJson = {
      'id': 'schedule-123',
      'studentName': 'María García',
      'studentId': 'student-456',
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': 'Clase individual',
      'status': 'confirmed',
      'notes': 'Clase de tenis',
      'price': 50.0,
      'tenantId': 'tenant-789',
      'tenantName': 'Centro Deportivo',
    };

    test('should create ClassScheduleModel from valid JSON', () {
      final schedule = ClassScheduleModel.fromJson(validJson);
      expect(schedule.id, equals('schedule-123'));
      expect(schedule.studentName, equals('María García'));
      expect(schedule.studentId, equals('student-456'));
      expect(schedule.type, equals('Clase individual'));
      expect(schedule.status, equals('confirmed'));
      expect(schedule.notes, equals('Clase de tenis'));
      expect(schedule.price, equals(50.0));
      expect(schedule.tenantId, equals('tenant-789'));
      expect(schedule.tenantName, equals('Centro Deportivo'));
    });

    test('should handle missing optional fields', () {
      final jsonWithoutOptionals = {
        'id': 'schedule-123',
        'studentName': 'María García',
        'studentId': 'student-456',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'type': 'Clase individual',
        'status': 'pending',
        'price': 50.0,
      };

      final schedule = ClassScheduleModel.fromJson(jsonWithoutOptionals);
      expect(schedule.notes, isNull);
      expect(schedule.tenantId, isNull);
      expect(schedule.tenantName, isNull);
    });

    test('should use alternative field names', () {
      final jsonWithAlternatives = {
        '_id': 'schedule-123',
        'studentName': 'María García',
        'studentId': 'student-456',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'serviceType': 'Clase grupal',
        'status': 'pending',
        'price': 50.0,
      };

      final schedule = ClassScheduleModel.fromJson(jsonWithAlternatives);
      expect(schedule.id, equals('schedule-123'));
      expect(schedule.type, equals('Clase grupal'));
    });

    test('should use default values when fields are missing', () {
      final jsonWithDefaults = {
        'id': 'schedule-123',
        'studentName': 'María García',
        'studentId': 'student-456',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'price': null,
      };

      final schedule = ClassScheduleModel.fromJson(jsonWithDefaults);
      expect(schedule.type, equals('Clase individual'));
      expect(schedule.status, equals('pending'));
      expect(schedule.price, equals(0.0));
    });

    test('should convert ClassScheduleModel to JSON', () {
      final schedule = ClassScheduleModel.fromJson(validJson);
      final json = schedule.toJson();

      expect(json['id'], equals('schedule-123'));
      expect(json['studentName'], equals('María García'));
      expect(json['studentId'], equals('student-456'));
      expect(json['type'], equals('Clase individual'));
      expect(json['status'], equals('confirmed'));
      expect(json['price'], equals(50.0));
    });

    test('should throw AssertionError for empty id in debug mode', () {
      final invalidJson = {
        'id': '',
        'studentName': 'María García',
        'studentId': 'student-456',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'type': 'Clase individual',
        'status': 'pending',
        'price': 50.0,
      };

      expect(
        () => ClassScheduleModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError for empty studentName in debug mode', () {
      final invalidJson = {
        'id': 'schedule-123',
        'studentName': '',
        'studentId': 'student-456',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'type': 'Clase individual',
        'status': 'pending',
        'price': 50.0,
      };

      expect(
        () => ClassScheduleModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError for empty studentId in debug mode', () {
      final invalidJson = {
        'id': 'schedule-123',
        'studentName': 'María García',
        'studentId': '',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'type': 'Clase individual',
        'status': 'pending',
        'price': 50.0,
      };

      expect(
        () => ClassScheduleModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should parse dates as UTC', () {
      final schedule = ClassScheduleModel.fromJson(validJson);
      expect(schedule.startTime.isUtc, isTrue);
      expect(schedule.endTime.isUtc, isTrue);
    });

    test('should be equal when properties match', () {
      final schedule1 = ClassScheduleModel.fromJson(validJson);
      final schedule2 = ClassScheduleModel.fromJson(validJson);

      expect(schedule1, equals(schedule2));
    });
  });
}

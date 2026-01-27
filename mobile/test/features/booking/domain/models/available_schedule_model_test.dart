import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/booking/domain/models/available_schedule_model.dart';

void main() {
  group('AvailableScheduleModel', () {
    final startTime = DateTime(2024, 1, 15, 10, 0);
    final endTime = DateTime(2024, 1, 15, 11, 0);

    final validJson = {
      'id': 'schedule-123',
      'professorId': 'prof-456',
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': 'available',
    };

    test('should create AvailableScheduleModel from valid JSON', () {
      final schedule = AvailableScheduleModel.fromJson(validJson);
      expect(schedule.id, equals('schedule-123'));
      expect(schedule.professorId, equals('prof-456'));
      expect(schedule.startDateTime, equals(startTime));
      expect(schedule.endDateTime, equals(endTime));
      expect(schedule.status, equals('available'));
    });

    test('should use default status when not provided', () {
      final jsonWithoutStatus = {
        'id': 'schedule-123',
        'professorId': 'prof-456',
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };

      final schedule = AvailableScheduleModel.fromJson(jsonWithoutStatus);
      expect(schedule.status, equals('available'));
    });

    test('should convert AvailableScheduleModel to JSON', () {
      final schedule = AvailableScheduleModel.fromJson(validJson);
      final json = schedule.toJson();

      expect(json['id'], equals('schedule-123'));
      expect(json['professorId'], equals('prof-456'));
      expect(json['startTime'], equals(startTime.toIso8601String()));
      expect(json['endTime'], equals(endTime.toIso8601String()));
      expect(json['status'], equals('available'));
    });

    test('should calculate duration in minutes correctly', () {
      final schedule = AvailableScheduleModel(
        id: 'schedule-123',
        professorId: 'prof-456',
        startTime: startTime,
        endTime: endTime,
        type: 'individual_class',
        price: 50.0,
        status: 'available',
      );

      expect(schedule.durationInMinutes, equals(60));
    });

    test('should format date correctly', () {
      final schedule = AvailableScheduleModel(
        id: 'schedule-123',
        professorId: 'prof-456',
        startTime: DateTime(2024, 1, 15, 10, 0),
        endTime: DateTime(2024, 1, 15, 11, 0),
        type: 'individual_class',
        price: 50.0,
        status: 'available',
      );

      expect(schedule.formattedDate, equals('lunes, 15 de enero'));
    });

    test('should format time range correctly', () {
      final schedule = AvailableScheduleModel(
        id: 'schedule-123',
        professorId: 'prof-456',
        startTime: DateTime(2024, 1, 15, 10, 30),
        endTime: DateTime(2024, 1, 15, 11, 45),
        type: 'individual_class',
        price: 50.0,
        status: 'available',
      );

      expect(schedule.formattedTimeRange, equals('10:30 AM - 11:45 AM'));
    });

    test('should handle different status values', () {
      final statuses = ['available', 'booked', 'cancelled', 'pending'];
      for (final status in statuses) {
        final json = {
          'id': 'schedule-123',
          'professorId': 'prof-456',
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'status': status,
        };

        final schedule = AvailableScheduleModel.fromJson(json);
        expect(schedule.status, equals(status));
      }
    });
  });
}

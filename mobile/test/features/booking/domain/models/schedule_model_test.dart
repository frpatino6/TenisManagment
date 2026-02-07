import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/booking/domain/models/schedule_model.dart';

void main() {
  group('ScheduleModel', () {
    test('should parse schedule from JSON correctly', () {
      final json = {
        'id': 'schedule-123',
        'date': '2025-12-06',
        'startTime': '2025-12-06T10:00:00Z',
        'endTime': '2025-12-06T11:00:00Z',
        'status': 'pending',
        'notes': 'Test schedule',
        'isAvailable': true,
        'isBlocked': false,
      };

      final schedule = ScheduleModel.fromJson(json);

      expect(schedule.id, equals('schedule-123'));
      expect(schedule.date, equals('2025-12-06'));
      expect(schedule.status, equals('pending'));
      expect(schedule.notes, equals('Test schedule'));
      expect(schedule.isAvailable, isTrue);
      expect(schedule.isBlocked, isFalse);
    });

    test('should format time range correctly', () {
      final schedule = ScheduleModel(
        id: 'test',
        startTime: DateTime(2025, 12, 6, 10, 30),
        endTime: DateTime(2025, 12, 6, 11, 45),
        status: 'pending',
        isAvailable: true,
      );

      expect(schedule.timeRange, equals('10:30 - 11:45'));
    });

    test('should format date correctly', () {
      final schedule = ScheduleModel(
        id: 'test',
        startTime: DateTime(2025, 12, 6, 10, 0),
        endTime: DateTime(2025, 12, 6, 11, 0),
        status: 'pending',
        isAvailable: true,
      );

      expect(schedule.formattedDate, equals('06/12/2025'));
    });

    test('should get day name correctly', () {
      // Friday, December 6, 2025
      final schedule = ScheduleModel(
        id: 'test',
        startTime: DateTime(2025, 12, 6, 10, 0),
        endTime: DateTime(2025, 12, 6, 11, 0),
        status: 'pending',
        isAvailable: true,
      );

      expect(schedule.dayName, equals('Sáb')); // Saturday
    });
  });

  group('TenantSchedulesGroup', () {
    test('should parse tenant schedules group from JSON correctly', () {
      final json = {
        'tenantId': 'tenant-123',
        'tenantName': 'Centro A',
        'tenantSlug': 'centro-a',
        'tenantLogo': 'https://example.com/logo.png',
        'schedules': [
          {
            'id': 'schedule-1',
            'startTime': '2025-12-06T10:00:00Z',
            'endTime': '2025-12-06T11:00:00Z',
            'status': 'pending',
            'isAvailable': true,
          },
        ],
      };

      final group = TenantSchedulesGroup.fromJson(json);

      expect(group.tenantId, equals('tenant-123'));
      expect(group.tenantName, equals('Centro A'));
      expect(group.tenantSlug, equals('centro-a'));
      expect(group.tenantLogo, equals('https://example.com/logo.png'));
      expect(group.schedules.length, equals(1));
      expect(group.schedules[0].id, equals('schedule-1'));
    });
  });

  group('ProfessorSchedulesResponse', () {
    test('should parse professor schedules response from JSON correctly', () {
      final json = {
        'professorId': 'prof-123',
        'professorName': 'Prof. Juan',
        'schedules': [
          {
            'tenantId': 'tenant-1',
            'tenantName': 'Centro A',
            'tenantSlug': 'centro-a',
            'schedules': [],
          },
        ],
      };

      final response = ProfessorSchedulesResponse.fromJson(json);

      expect(response.professorId, equals('prof-123'));
      expect(response.professorName, equals('Prof. Juan'));
      expect(response.schedules.length, equals(1));
      expect(response.schedules[0].tenantId, equals('tenant-1'));
    });
  });
}

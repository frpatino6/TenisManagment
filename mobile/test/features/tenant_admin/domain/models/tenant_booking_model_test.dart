import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/tenant_booking_model.dart';

void main() {
  group('TenantBookingModel', () {
    test('should parse from JSON with standard keys', () {
      final json = {
        'id': '123',
        'serviceType': 'court_rental',
        'status': 'confirmed',
        'price': 50.0,
        'date': '2024-01-01T10:00:00.000Z',
        'court': {'id': 'c1', 'name': 'Cancha 1', 'type': 'tennis'},
        'student': {
          'id': 's1',
          'name': 'Student 1',
          'email': 'student@test.com',
        },
      };

      final model = TenantBookingModel.fromJson(json);

      expect(model.id, '123');
      expect(model.serviceType, 'court_rental');
      expect(model.status, 'confirmed');
      expect(model.price, 50.0);
      expect(model.date, isNotNull);
      expect(model.court?.name, 'Cancha 1');
      expect(model.student.name, 'Student 1');
    });

    test(
      'should parse from JSON with alternate keys (_id, totalPrice, bookingDate)',
      () {
        final json = {
          '_id': '123',
          'serviceType': 'individual_class',
          'status': 'pending',
          'totalPrice': 100, // Testing int to double conversion
          'bookingDate': '2024-01-01T10:00:00.000Z',
          'professor': {
            'id': 'p1',
            'name': 'Professor 1',
            'email': 'prof@test.com',
          },
        };

        final model = TenantBookingModel.fromJson(json);

        expect(model.id, '123');
        expect(model.price, 100.0);
        expect(model.serviceType, 'individual_class');
        expect(model.professor?.name, 'Professor 1');
      },
    );

    test('should handle missing optional fields gracefully', () {
      final json = {
        'id': '123',
        'serviceType': 'court_rental',
        'status': 'confirmed',
        'price': 50.0,
      };

      final model = TenantBookingModel.fromJson(json);

      expect(model.id, '123');
      expect(model.court, isNull);
      expect(model.professor, isNull);
      expect(model.student.name, 'Estudiante no encontrado');
      expect(model.startTime, isNull);
    });

    test('should parse startTime and endTime from bookingDate and endTime for court_rental', () {
      final json = {
        'id': '123',
        'serviceType': 'court_rental',
        'status': 'confirmed',
        'price': 50.0,
        'bookingDate': '2026-01-26T10:00:00.000Z',
        'endTime': '2026-01-26T11:00:00.000Z',
        'student': {
          'id': 's1',
          'name': 'Student 1',
          'email': 'student@test.com',
        },
      };

      final model = TenantBookingModel.fromJson(json);

      expect(model.startTime, isNotNull);
      expect(model.endTime, isNotNull);
      expect(model.startTime!.toIso8601String(), '2026-01-26T10:00:00.000Z');
      expect(model.endTime!.toIso8601String(), '2026-01-26T11:00:00.000Z');
    });

    test('should parse startTime and endTime from schedule for bookings with schedule', () {
      final json = {
        'id': '123',
        'serviceType': 'individual_class',
        'status': 'confirmed',
        'price': 100.0,
        'date': '2026-01-26T00:00:00.000Z',
        'startTime': '2026-01-26T14:00:00.000Z',
        'endTime': '2026-01-26T15:00:00.000Z',
        'student': {
          'id': 's1',
          'name': 'Student 1',
          'email': 'student@test.com',
        },
        'professor': {
          'id': 'p1',
          'name': 'Professor 1',
          'email': 'prof@test.com',
        },
      };

      final model = TenantBookingModel.fromJson(json);

      expect(model.startTime, isNotNull);
      expect(model.endTime, isNotNull);
      expect(model.startTime!.toIso8601String(), '2026-01-26T14:00:00.000Z');
      expect(model.endTime!.toIso8601String(), '2026-01-26T15:00:00.000Z');
    });

    test('should handle null values for optional fields', () {
      final json = {
        'id': '123',
        'serviceType': 'court_rental',
        'status': 'confirmed',
        'price': 50.0,
        'court': null,
        'professor': null,
        'student': null,
      };

      final model = TenantBookingModel.fromJson(json);

      expect(model.court, isNull);
      expect(model.professor, isNull);
      expect(model.student.name, 'Estudiante no encontrado');
    });
  });
}

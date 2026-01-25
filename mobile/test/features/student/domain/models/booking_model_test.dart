import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/student/domain/models/booking_model.dart';

void main() {
  group('BookingModel', () {
    final validJson = {
      'id': 'booking-123',
      'professor': {
        'id': 'prof-456',
        'name': 'Juan Pérez',
        'email': 'juan@example.com',
        'specialties': ['Tenis'],
        'pricing': {
          'individual_class': 50.0,
          'group_class': 30.0,
          'court_rental': 20.0,
        },
      },
      'schedule': {
        'id': 'schedule-789',
        'professorId': 'prof-456',
        'startTime': '2024-01-15T10:00:00.000Z',
        'endTime': '2024-01-15T11:00:00.000Z',
        'type': 'individual_class',
        'price': 50.0,
        'status': 'pending',
      },
      'serviceType': 'individual_class',
      'price': 50.0,
      'status': 'confirmed',
      'createdAt': '2024-01-15T09:00:00.000Z',
    };

    test('should create BookingModel from valid JSON', () {
      final booking = BookingModel.fromJson(validJson);
      expect(booking.id, equals('booking-123'));
      expect(booking.professor.id, equals('prof-456'));
      expect(booking.professor.name, equals('Juan Pérez'));
      expect(booking.schedule.id, equals('schedule-789'));
      expect(booking.serviceType, equals('individual_class'));
      expect(booking.price, equals(50.0));
      expect(booking.status, equals('confirmed'));
    });

    test('should handle missing optional fields', () {
      final jsonWithoutCourt = {
        'id': 'booking-123',
        'professor': {
          'id': 'prof-456',
          'name': 'Juan Pérez',
          'email': 'juan@example.com',
          'specialties': <String>[],
          'pricing': <String, dynamic>{},
        },
        'schedule': {
          'id': 'schedule-789',
          'professorId': 'prof-456',
          'startTime': '2024-01-15T10:00:00.000Z',
          'endTime': '2024-01-15T11:00:00.000Z',
          'type': 'individual_class',
          'price': 50.0,
          'status': 'pending',
        },
        'serviceType': 'individual_class',
        'price': 50.0,
        'status': 'pending',
      };

      final booking = BookingModel.fromJson(jsonWithoutCourt);
      expect(booking.court, isNull);
      expect(booking.status, equals('pending'));
    });

    test('should use default values when fields are missing', () {
      final jsonWithDefaults = {
        'id': 'booking-123',
        'professor': {
          'id': 'prof-456',
          'name': 'Juan Pérez',
          'email': 'juan@example.com',
          'specialties': <String>[],
          'pricing': <String, dynamic>{},
        },
        'schedule': {
          'id': 'schedule-789',
          'professorId': 'prof-456',
          'startTime': '2024-01-15T10:00:00.000Z',
          'endTime': '2024-01-15T11:00:00.000Z',
          'type': 'individual_class',
          'price': 50.0,
          'status': 'pending',
        },
      };

      final booking = BookingModel.fromJson(jsonWithDefaults);
      expect(booking.serviceType, equals('individual_class'));
      expect(booking.status, equals('pending'));
    });

    test('should convert BookingModel to JSON', () {
      final booking = BookingModel.fromJson(validJson);
      final json = booking.toJson();

      expect(json['id'], equals('booking-123'));
      expect(json['serviceType'], equals('individual_class'));
      expect(json['price'], equals(50.0));
      expect(json['status'], equals('confirmed'));
      expect(json['professor'], isA<Map<String, dynamic>>());
      expect(json['schedule'], isA<Map<String, dynamic>>());
    });

    test('should throw AssertionError for empty id in debug mode', () {
      final invalidJson = {
        'id': '',
        'professor': {
          'id': 'prof-456',
          'name': 'Juan Pérez',
          'email': 'juan@example.com',
          'specialties': <String>[],
          'pricing': <String, dynamic>{},
        },
        'schedule': {
          'id': 'schedule-789',
          'professorId': 'prof-456',
          'startTime': '2024-01-15T10:00:00.000Z',
          'endTime': '2024-01-15T11:00:00.000Z',
          'type': 'individual_class',
          'price': 50.0,
          'status': 'pending',
        },
        'serviceType': 'individual_class',
        'price': 50.0,
        'status': 'pending',
      };

      expect(
        () => BookingModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test(
      'should throw AssertionError for invalid serviceType in debug mode',
      () {
        final invalidJson = {
          'id': 'booking-123',
          'professor': {
            'id': 'prof-456',
            'name': 'Juan Pérez',
            'email': 'juan@example.com',
            'specialties': <String>[],
            'pricing': <String, dynamic>{},
          },
          'schedule': {
            'id': 'schedule-789',
            'professorId': 'prof-456',
            'startTime': '2024-01-15T10:00:00.000Z',
            'endTime': '2024-01-15T11:00:00.000Z',
            'type': 'individual_class',
            'price': 50.0,
            'status': 'pending',
          },
          'serviceType': 'invalid_type',
          'price': 50.0,
          'status': 'pending',
        };

        expect(
          () => BookingModel.fromJson(invalidJson),
          throwsA(isA<AssertionError>()),
        );
      },
    );

    test('should accept valid service types', () {
      final types = ['individual_class', 'group_class', 'court_rental'];
      for (final type in types) {
        final json = {
          'id': 'booking-123',
          'professor': {
            'id': 'prof-456',
            'name': 'Juan Pérez',
            'email': 'juan@example.com',
            'specialties': <String>[],
            'pricing': <String, dynamic>{},
          },
          'schedule': {
            'id': 'schedule-789',
            'professorId': 'prof-456',
            'startTime': '2024-01-15T10:00:00.000Z',
            'endTime': '2024-01-15T11:00:00.000Z',
            'type': type,
            'price': 50.0,
            'status': 'pending',
          },
          'serviceType': type,
          'price': 50.0,
          'status': 'pending',
        };

        expect(() => BookingModel.fromJson(json), returnsNormally);
      }
    });

    test('should accept valid status values', () {
      final statuses = ['pending', 'confirmed', 'cancelled', 'completed'];
      for (final status in statuses) {
        final json = {
          'id': 'booking-123',
          'professor': {
            'id': 'prof-456',
            'name': 'Juan Pérez',
            'email': 'juan@example.com',
            'specialties': <String>[],
            'pricing': <String, dynamic>{},
          },
          'schedule': {
            'id': 'schedule-789',
            'professorId': 'prof-456',
            'startTime': '2024-01-15T10:00:00.000Z',
            'endTime': '2024-01-15T11:00:00.000Z',
            'type': 'individual_class',
            'price': 50.0,
            'status': 'pending',
          },
          'serviceType': 'individual_class',
          'price': 50.0,
          'status': status,
        };

        expect(() => BookingModel.fromJson(json), returnsNormally);
      }
    });
  });

  group('CourtBookingModel', () {
    final validJson = {
      'id': 'court-123',
      'name': 'Cancha 1',
      'type': 'tennis',
      'price': 25.0,
    };

    test('should create CourtBookingModel from valid JSON', () {
      final court = CourtBookingModel.fromJson(validJson);
      expect(court.id, equals('court-123'));
      expect(court.name, equals('Cancha 1'));
      expect(court.type, equals('tennis'));
      expect(court.price, equals(25.0));
    });

    test('should use default values when fields are missing', () {
      final jsonWithDefaults = {
        'id': '',
        'name': null,
        'type': null,
        'price': null,
      };

      final court = CourtBookingModel.fromJson(jsonWithDefaults);
      expect(court.id, equals(''));
      expect(court.name, equals('Cancha'));
      expect(court.type, equals('tennis'));
      expect(court.price, equals(0.0));
    });

    test('should accept valid court types', () {
      final types = ['tennis', 'padel', 'multi'];
      for (final type in types) {
        final json = {
          'id': 'court-123',
          'name': 'Cancha 1',
          'type': type,
          'price': 25.0,
        };

        expect(() => CourtBookingModel.fromJson(json), returnsNormally);
      }
    });
  });

  group('ProfessorBookingModel (student)', () {
    final validJson = {
      'id': 'prof-456',
      'name': 'Juan Pérez',
      'email': 'juan@example.com',
      'specialties': ['Tenis', 'Padel'],
      'pricing': {
        'individual_class': 50.0,
        'group_class': 30.0,
        'court_rental': 20.0,
      },
    };

    test('should create ProfessorBookingModel from valid JSON', () {
      final professor = ProfessorBookingModel.fromJson(validJson);
      expect(professor.id, equals('prof-456'));
      expect(professor.name, equals('Juan Pérez'));
      expect(professor.email, equals('juan@example.com'));
      expect(professor.specialties, equals(['Tenis', 'Padel']));
      expect(professor.pricing, isA<PricingConfig>());
      expect(professor.pricing.individualClass, equals(50.0));
    });

    test('should use default values when fields are missing', () {
      final jsonWithDefaults = {
        'id': null,
        'name': null,
        'email': null,
        'specialties': null,
        'pricing': null,
      };

      final professor = ProfessorBookingModel.fromJson(jsonWithDefaults);
      expect(professor.id, equals(''));
      expect(professor.name, equals('Profesor no disponible'));
      expect(professor.email, equals(''));
      expect(professor.specialties, isEmpty);
      expect(professor.pricing.individualClass, equals(0.0));
      expect(professor.pricing.groupClass, equals(0.0));
      expect(professor.pricing.courtRental, equals(0.0));
    });
  });
}

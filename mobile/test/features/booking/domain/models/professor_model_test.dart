import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/booking/domain/models/professor_model.dart';

void main() {
  group('PricingConfig', () {
    final validJson = {
      'individualClass': 50.0,
      'groupClass': 30.0,
      'courtRental': 25.0,
    };

    test('should create PricingConfig from valid JSON', () {
      final pricing = PricingConfig.fromJson(validJson);
      expect(pricing.individualClass, equals(50.0));
      expect(pricing.groupClass, equals(30.0));
      expect(pricing.courtRental, equals(25.0));
    });

    test('should handle integer values in JSON', () {
      final jsonWithInts = {
        'individualClass': 50,
        'groupClass': 30,
        'courtRental': 25,
      };

      final pricing = PricingConfig.fromJson(jsonWithInts);
      expect(pricing.individualClass, equals(50.0));
      expect(pricing.groupClass, equals(30.0));
      expect(pricing.courtRental, equals(25.0));
    });
  });

  group('ProfessorBookingModel', () {
    final validJson = {
      'id': 'prof-123',
      'name': 'Juan Pérez',
      'email': 'juan@example.com',
      'phone': '+1234567890',
      'specialties': ['Tenis', 'Padel'],
      'hourlyRate': 50.0,
      'pricing': {
        'individualClass': 50.0,
        'groupClass': 30.0,
        'courtRental': 25.0,
      },
      'experienceYears': 5,
      'rating': 4.5,
    };

    test('should create ProfessorBookingModel from valid JSON', () {
      final professor = ProfessorBookingModel.fromJson(validJson);
      expect(professor.id, equals('prof-123'));
      expect(professor.name, equals('Juan Pérez'));
      expect(professor.email, equals('juan@example.com'));
      expect(professor.phone, equals('+1234567890'));
      expect(professor.specialties, equals(['Tenis', 'Padel']));
      expect(professor.hourlyRate, equals(50.0));
      expect(professor.experienceYears, equals(5));
      expect(professor.rating, equals(4.5));
      expect(professor.pricing.individualClass, equals(50.0));
    });

    test('should handle missing optional fields', () {
      final jsonWithoutPhone = {
        'id': 'prof-123',
        'name': 'Juan Pérez',
        'email': 'juan@example.com',
        'specialties': [],
        'hourlyRate': 50.0,
        'pricing': {
          'individualClass': 50.0,
          'groupClass': 30.0,
          'courtRental': 25.0,
        },
        'experienceYears': 0,
        'rating': 0.0,
      };

      final professor = ProfessorBookingModel.fromJson(jsonWithoutPhone);
      expect(professor.phone, equals(''));
      expect(professor.specialties, isEmpty);
      expect(professor.experienceYears, equals(0));
      expect(professor.rating, equals(0.0));
    });

    test('should handle null optional fields', () {
      final jsonWithNulls = {
        'id': 'prof-123',
        'name': 'Juan Pérez',
        'email': 'juan@example.com',
        'phone': null,
        'specialties': null,
        'hourlyRate': null,
        'pricing': {
          'individualClass': 50.0,
          'groupClass': 30.0,
          'courtRental': 25.0,
        },
        'experienceYears': null,
        'rating': null,
      };

      final professor = ProfessorBookingModel.fromJson(jsonWithNulls);
      expect(professor.phone, equals(''));
      expect(professor.specialties, isEmpty);
      expect(professor.hourlyRate, equals(0.0));
      expect(professor.experienceYears, equals(0));
      expect(professor.rating, equals(0.0));
    });

    test('should convert ProfessorBookingModel to JSON', () {
      final pricing = PricingConfig(
        individualClass: 50.0,
        groupClass: 30.0,
        courtRental: 25.0,
      );

      final professor = ProfessorBookingModel(
        id: 'prof-123',
        name: 'Juan Pérez',
        email: 'juan@example.com',
        phone: '+1234567890',
        specialties: ['Tenis', 'Padel'],
        hourlyRate: 50.0,
        pricing: pricing,
        experienceYears: 5,
        rating: 4.5,
      );

      final json = professor.toJson();
      expect(json['id'], equals('prof-123'));
      expect(json['name'], equals('Juan Pérez'));
      expect(json['email'], equals('juan@example.com'));
      expect(json['phone'], equals('+1234567890'));
      expect(json['specialties'], equals(['Tenis', 'Padel']));
      expect(json['hourlyRate'], equals(50.0));
      expect(json['experienceYears'], equals(5));
      expect(json['rating'], equals(4.5));
    });
  });
}

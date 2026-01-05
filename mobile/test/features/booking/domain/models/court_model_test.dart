import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/booking/domain/models/court_model.dart';
import 'package:tennis_management/core/exceptions/validation_exception.dart';

void main() {
  group('CourtModel', () {
    final validJson = {
      'id': 'court-123',
      'name': 'Cancha 1',
      'type': 'tennis',
      'pricePerHour': 50.0,
      'features': ['Iluminación', 'Césped sintético'],
    };

    test('should create CourtModel from valid JSON', () {
      final court = CourtModel.fromJson(validJson);
      expect(court.id, equals('court-123'));
      expect(court.name, equals('Cancha 1'));
      expect(court.type, equals('tennis'));
      expect(court.pricePerHour, equals(50.0));
      expect(court.features, equals(['Iluminación', 'Césped sintético']));
    });

    test('should convert CourtModel to JSON', () {
      final court = CourtModel.fromJson(validJson);
      final json = court.toJson();

      expect(json['id'], equals('court-123'));
      expect(json['name'], equals('Cancha 1'));
      expect(json['type'], equals('tennis'));
      expect(json['pricePerHour'], equals(50.0));
      expect(json['features'], isA<List>());
    });

    test('should handle missing optional fields', () {
      final jsonWithoutFeatures = {
        'id': 'court-123',
        'name': 'Cancha 1',
        'type': 'padel',
        'pricePerHour': 30.0,
      };

      final court = CourtModel.fromJson(jsonWithoutFeatures);
      expect(court.id, equals('court-123'));
      expect(court.features, isEmpty);
    });

    test('should throw AssertionError for negative price in debug mode', () {
      final invalidJson = {
        'id': 'court-123',
        'name': 'Cancha 1',
        'type': 'tennis',
        'pricePerHour': -10.0,
      };

      expect(
        () => CourtModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError for empty id in debug mode', () {
      final invalidJson = {
        'id': '',
        'name': 'Cancha 1',
        'type': 'tennis',
        'pricePerHour': 50.0,
      };

      expect(
        () => CourtModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError for empty name in debug mode', () {
      final invalidJson = {
        'id': 'court-123',
        'name': '',
        'type': 'tennis',
        'pricePerHour': 50.0,
      };

      expect(
        () => CourtModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should throw AssertionError for invalid type in debug mode', () {
      final invalidJson = {
        'id': 'court-123',
        'name': 'Cancha 1',
        'type': 'invalid',
        'pricePerHour': 50.0,
      };

      expect(
        () => CourtModel.fromJson(invalidJson),
        throwsA(isA<AssertionError>()),
      );
    });

    test('should handle null features gracefully', () {
      final jsonWithNullFeatures = {
        'id': 'court-123',
        'name': 'Cancha 1',
        'type': 'tennis',
        'pricePerHour': 50.0,
        'features': null,
      };

      final court = CourtModel.fromJson(jsonWithNullFeatures);
      expect(court.features, isEmpty);
    });

    test('should accept valid court types', () {
      final types = ['tennis', 'padel', 'multi'];
      for (final type in types) {
        final json = {
          'id': 'court-123',
          'name': 'Cancha 1',
          'type': type,
          'pricePerHour': 50.0,
        };

        expect(() => CourtModel.fromJson(json), returnsNormally);
      }
    });
  });
}

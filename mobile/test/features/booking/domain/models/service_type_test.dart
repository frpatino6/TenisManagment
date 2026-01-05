import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/booking/domain/models/service_type.dart';
import 'package:tennis_management/features/booking/domain/models/professor_model.dart';

void main() {
  group('ServiceType', () {
    test('should have all three service types', () {
      expect(ServiceType.values.length, equals(3));
      expect(ServiceType.individualClass.value, equals('individual_class'));
      expect(ServiceType.groupClass.value, equals('group_class'));
      expect(ServiceType.courtRental.value, equals('court_rental'));
    });

    test('should have correct display names', () {
      expect(
        ServiceType.individualClass.displayName,
        equals('Clase Individual'),
      );
      expect(ServiceType.groupClass.displayName, equals('Clase Grupal'));
      expect(ServiceType.courtRental.displayName, equals('Alquiler de Cancha'));
    });

    test('fromValue should return correct ServiceType', () {
      expect(
        ServiceType.fromValue('individual_class'),
        equals(ServiceType.individualClass),
      );
      expect(
        ServiceType.fromValue('group_class'),
        equals(ServiceType.groupClass),
      );
      expect(
        ServiceType.fromValue('court_rental'),
        equals(ServiceType.courtRental),
      );
    });

    test('fromValue should return default for unknown value', () {
      expect(
        ServiceType.fromValue('unknown'),
        equals(ServiceType.individualClass),
      );
    });

    test('getPrice should return correct price from PricingConfig', () {
      final pricing = PricingConfig(
        individualClass: 50.0,
        groupClass: 30.0,
        courtRental: 25.0,
      );

      expect(ServiceType.individualClass.getPrice(pricing), equals(50.0));
      expect(ServiceType.groupClass.getPrice(pricing), equals(30.0));
      expect(ServiceType.courtRental.getPrice(pricing), equals(25.0));
    });
  });
}

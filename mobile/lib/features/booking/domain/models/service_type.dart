import 'professor_model.dart';

enum ServiceType {
  individualClass('individual_class', 'Clase Individual'),
  groupClass('group_class', 'Clase Grupal'),
  courtRental('court_rental', 'Alquiler de Cancha');

  const ServiceType(this.value, this.displayName);

  final String value;
  final String displayName;

  static ServiceType fromValue(String value) {
    return ServiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ServiceType.individualClass,
    );
  }
  
  /// Get price for this service type from professor's pricing
  double getPrice(PricingConfig pricing) {
    switch (this) {
      case ServiceType.individualClass:
        return pricing.individualClass;
      case ServiceType.groupClass:
        return pricing.groupClass;
      case ServiceType.courtRental:
        return pricing.courtRental;
    }
  }
}

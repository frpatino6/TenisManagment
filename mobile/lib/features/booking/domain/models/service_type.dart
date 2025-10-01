enum ServiceType {
  individualClass('individual_class', 'Clase Individual', 50000),
  groupClass('group_class', 'Clase Grupal', 35000),
  courtRental('court_rental', 'Alquiler de Cancha', 25000);

  const ServiceType(this.value, this.displayName, this.defaultPrice);

  final String value;
  final String displayName;
  final double defaultPrice;

  static ServiceType fromValue(String value) {
    return ServiceType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ServiceType.individualClass,
    );
  }
}

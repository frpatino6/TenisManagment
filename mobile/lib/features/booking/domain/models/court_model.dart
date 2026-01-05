import '../../../../core/validation/model_validator.dart';

/// Model for representing a court (cancha) in the system
class CourtModel {
  final String id;
  final String name;
  final String type; // 'tennis' | 'padel' | 'multi'
  final double pricePerHour;
  final String? description;
  final List<String> features;

  CourtModel({
    required this.id,
    required this.name,
    required this.type,
    required this.pricePerHour,
    this.description,
    this.features = const [],
  }) {
    // Validation in constructor
    assert(id.isNotEmpty, 'Court id must not be empty');
    assert(name.isNotEmpty, 'Court name must not be empty');
    assert(
      ['tennis', 'padel', 'multi'].contains(type),
      'Court type must be tennis, padel, or multi',
    );
    ModelValidator.validatePrice(pricePerHour);
  }

  factory CourtModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String? ?? json['_id'] as String? ?? '';
    final name = json['name'] as String? ?? '';
    final type = json['type'] as String? ?? 'tennis';
    final pricePerHour = ModelValidator.parseDouble(
      json['pricePerHour'],
      'pricePerHour',
      defaultValue: 0.0,
    );
    
    return CourtModel(
      id: id,
      name: name,
      type: type,
      pricePerHour: pricePerHour,
      description: json['description'] as String?,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'pricePerHour': pricePerHour,
      'description': description,
      'features': features,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case 'tennis':
        return 'Tenis';
      case 'padel':
        return 'Padel';
      case 'multi':
        return 'Multi-deporte';
      default:
        return type;
    }
  }

  String get formattedPrice => '\$${pricePerHour.toStringAsFixed(0)}';
}


/// Model for Court in Tenant Admin context
/// Reuses structure from booking CourtModel but adapted for tenant admin
class TenantCourtModel {
  final String id;
  final String name;
  final String type; // 'tennis' | 'padel' | 'multi'
  final double price;
  final bool isActive;
  final String? description;
  final List<String> features;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TenantCourtModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.isActive,
    this.description,
    required this.features,
    this.createdAt,
    this.updatedAt,
  });

  factory TenantCourtModel.fromJson(Map<String, dynamic> json) {
    return TenantCourtModel(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String? ?? 'tennis',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isActive: json['isActive'] as bool? ?? true,
      description: json['description'] as String?,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
      'isActive': isActive,
      'description': description,
      'features': features,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
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

  String get formattedPrice => '\$${price.toStringAsFixed(0)}';
}

class CreateCourtRequest {
  final String name;
  final String type;
  final double price;
  final String? description;
  final List<String> features;

  CreateCourtRequest({
    required this.name,
    required this.type,
    required this.price,
    this.description,
    required this.features,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'type': type,
      'price': price,
      if (description != null) 'description': description,
      'features': features,
    };
  }
}

class UpdateCourtRequest {
  final String? name;
  final String? type;
  final double? price;
  final bool? isActive;
  final String? description;
  final List<String>? features;

  UpdateCourtRequest({
    this.name,
    this.type,
    this.price,
    this.isActive,
    this.description,
    this.features,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{};
    if (name != null) json['name'] = name;
    if (type != null) json['type'] = type;
    if (price != null) json['price'] = price;
    if (isActive != null) json['isActive'] = isActive;
    if (description != null) json['description'] = description;
    if (features != null) json['features'] = features;
    return json;
  }
}


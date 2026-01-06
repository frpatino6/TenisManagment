import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';
import '../../../../core/validation/model_validator.dart';

class TenantCourtModel extends Equatable {
  final String id;
  final String name;
  final String type; // 'tennis' | 'padel' | 'multi'
  final double price; // Precio por hora (backend uses 'price', not 'pricePerHour')
  final bool isActive;
  final String? description;
  final List<String> features;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TenantCourtModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
    required this.isActive,
    this.description,
    this.features = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory TenantCourtModel.fromJson(Map<String, dynamic> json) {
    return TenantCourtModel(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'tennis',
      price: ModelValidator.parseDouble(json['price'], 'price'),
      isActive: json['isActive'] as bool? ?? true,
      description: json['description']?.toString(),
      features: (json['features'] as List<dynamic>?)
          ?.map((e) => e.toString())
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
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  TenantCourtModel copyWith({
    String? id,
    String? name,
    String? type,
    double? price,
    bool? isActive,
    String? description,
    List<String>? features,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantCourtModel(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      description: description ?? this.description,
      features: features ?? this.features,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
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

  String get formattedPrice {
    final formatter = NumberFormat.currency(
      locale: 'es_CO',
      symbol: '\$',
      decimalDigits: 0,
    );
    return formatter.format(price);
  }

  @override
  List<Object?> get props => [
        id,
        name,
        type,
        price,
        isActive,
        description,
        features,
        createdAt,
        updatedAt,
      ];
}


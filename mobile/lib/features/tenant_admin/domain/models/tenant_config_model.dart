/// Model for Tenant configuration
class TenantConfigModel {
  final String id;
  final String name;
  final String slug;
  final String? domain;
  final TenantConfigData? config;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TenantConfigModel({
    required this.id,
    required this.name,
    required this.slug,
    this.domain,
    this.config,
    required this.isActive,
    this.createdAt,
    this.updatedAt,
  });

  factory TenantConfigModel.fromJson(Map<String, dynamic> json) {
    return TenantConfigModel(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      domain: json['domain'] as String?,
      config: json['config'] != null
          ? TenantConfigData.fromJson(json['config'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
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
      'slug': slug,
      'domain': domain,
      'config': config?.toJson(),
      'isActive': isActive,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  TenantConfigModel copyWith({
    String? id,
    String? name,
    String? slug,
    String? domain,
    TenantConfigData? config,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TenantConfigModel(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      domain: domain ?? this.domain,
      config: config ?? this.config,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TenantConfigData {
  final String? logo;
  final String? primaryColor;
  final String? secondaryColor;
  final BasePricing? basePricing;
  final OperatingHours? operatingHours;

  TenantConfigData({
    this.logo,
    this.primaryColor,
    this.secondaryColor,
    this.basePricing,
    this.operatingHours,
  });

  factory TenantConfigData.fromJson(Map<String, dynamic> json) {
    return TenantConfigData(
      logo: json['logo'] as String?,
      primaryColor: json['primaryColor'] as String?,
      secondaryColor: json['secondaryColor'] as String?,
      basePricing: json['basePricing'] != null
          ? BasePricing.fromJson(json['basePricing'] as Map<String, dynamic>)
          : null,
      operatingHours: json['operatingHours'] != null
          ? OperatingHours.fromJson(
              json['operatingHours'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo': logo,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'basePricing': basePricing?.toJson(),
      'operatingHours': operatingHours?.toJson(),
    };
  }

  TenantConfigData copyWith({
    String? logo,
    String? primaryColor,
    String? secondaryColor,
    BasePricing? basePricing,
    OperatingHours? operatingHours,
  }) {
    return TenantConfigData(
      logo: logo ?? this.logo,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      basePricing: basePricing ?? this.basePricing,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }
}

class BasePricing {
  final double individualClass;
  final double groupClass;
  final double courtRental;

  BasePricing({
    required this.individualClass,
    required this.groupClass,
    required this.courtRental,
  });

  factory BasePricing.fromJson(Map<String, dynamic> json) {
    return BasePricing(
      individualClass:
          (json['individualClass'] as num?)?.toDouble() ?? 0.0,
      groupClass: (json['groupClass'] as num?)?.toDouble() ?? 0.0,
      courtRental: (json['courtRental'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'individualClass': individualClass,
      'groupClass': groupClass,
      'courtRental': courtRental,
    };
  }
}

class OperatingHours {
  final String open; // Format: "HH:mm"
  final String close; // Format: "HH:mm"
  final List<int>? daysOfWeek; // 0-6, where 0=Sunday, 6=Saturday

  OperatingHours({
    required this.open,
    required this.close,
    this.daysOfWeek,
  });

  factory OperatingHours.fromJson(Map<String, dynamic> json) {
    return OperatingHours(
      open: json['open'] as String? ?? '06:00',
      close: json['close'] as String? ?? '22:00',
      daysOfWeek: json['daysOfWeek'] != null
          ? (json['daysOfWeek'] as List<dynamic>)
              .map((e) => e as int)
              .toList()
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      if (daysOfWeek != null) 'daysOfWeek': daysOfWeek,
    };
  }
}


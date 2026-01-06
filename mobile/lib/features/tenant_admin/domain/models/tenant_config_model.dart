import 'package:equatable/equatable.dart';

class TenantConfigModel extends Equatable {
  final String id;
  final String name;
  final String slug;
  final String? domain;
  final TenantConfigData? config;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const TenantConfigModel({
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
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      domain: json['domain']?.toString(),
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

  @override
  List<Object?> get props => [
        id,
        name,
        slug,
        domain,
        config,
        isActive,
        createdAt,
        updatedAt,
      ];
}

class TenantConfigData extends Equatable {
  final String? logo;
  final String? primaryColor;
  final String? secondaryColor;
  final BasePricingModel? basePricing;
  final OperatingHoursModel? operatingHours;

  const TenantConfigData({
    this.logo,
    this.primaryColor,
    this.secondaryColor,
    this.basePricing,
    this.operatingHours,
  });

  factory TenantConfigData.fromJson(Map<String, dynamic> json) {
    return TenantConfigData(
      logo: json['logo']?.toString(),
      primaryColor: json['primaryColor']?.toString(),
      secondaryColor: json['secondaryColor']?.toString(),
      basePricing: json['basePricing'] != null
          ? BasePricingModel.fromJson(
              json['basePricing'] as Map<String, dynamic>,
            )
          : null,
      operatingHours: json['operatingHours'] != null
          ? OperatingHoursModel.fromJson(
              json['operatingHours'] as Map<String, dynamic>,
            )
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
    BasePricingModel? basePricing,
    OperatingHoursModel? operatingHours,
  }) {
    return TenantConfigData(
      logo: logo ?? this.logo,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      basePricing: basePricing ?? this.basePricing,
      operatingHours: operatingHours ?? this.operatingHours,
    );
  }

  @override
  List<Object?> get props => [
        logo,
        primaryColor,
        secondaryColor,
        basePricing,
        operatingHours,
      ];
}

class BasePricingModel extends Equatable {
  final double individualClass;
  final double groupClass;
  final double courtRental;

  const BasePricingModel({
    required this.individualClass,
    required this.groupClass,
    required this.courtRental,
  });

  factory BasePricingModel.fromJson(Map<String, dynamic> json) {
    return BasePricingModel(
      individualClass: (json['individualClass'] as num?)?.toDouble() ?? 0.0,
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

  BasePricingModel copyWith({
    double? individualClass,
    double? groupClass,
    double? courtRental,
  }) {
    return BasePricingModel(
      individualClass: individualClass ?? this.individualClass,
      groupClass: groupClass ?? this.groupClass,
      courtRental: courtRental ?? this.courtRental,
    );
  }

  @override
  List<Object?> get props => [individualClass, groupClass, courtRental];
}

class OperatingHoursModel extends Equatable {
  final String open; // Format: "HH:mm"
  final String close; // Format: "HH:mm"
  final List<int> daysOfWeek; // 0-6 (0 = Sunday, 6 = Saturday)

  const OperatingHoursModel({
    required this.open,
    required this.close,
    required this.daysOfWeek,
  });

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) {
    return OperatingHoursModel(
      open: json['open']?.toString() ?? '08:00',
      close: json['close']?.toString() ?? '20:00',
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'open': open,
      'close': close,
      'daysOfWeek': daysOfWeek,
    };
  }

  OperatingHoursModel copyWith({
    String? open,
    String? close,
    List<int>? daysOfWeek,
  }) {
    return OperatingHoursModel(
      open: open ?? this.open,
      close: close ?? this.close,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  @override
  List<Object?> get props => [open, close, daysOfWeek];
}


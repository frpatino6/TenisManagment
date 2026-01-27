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
  final String? website;
  final String? address;
  final BasePricingModel? basePricing;
  final OperatingHoursModel? operatingHours;
  final PaymentsConfigModel? payments;

  const TenantConfigData({
    this.logo,
    this.website,
    this.address,
    this.basePricing,
    this.operatingHours,
    this.payments,
  });

  factory TenantConfigData.fromJson(Map<String, dynamic> json) {
    return TenantConfigData(
      logo: json['logo']?.toString(),
      website: json['website']?.toString(),
      address: json['address']?.toString(),
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
      payments: json['payments'] != null
          ? PaymentsConfigModel.fromJson(
              json['payments'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logo': logo,
      'website': website,
      'address': address,
      'basePricing': basePricing?.toJson(),
      'operatingHours': operatingHours?.toJson(),
      'payments': payments?.toJson(),
    };
  }

  TenantConfigData copyWith({
    String? logo,
    String? website,
    String? address,
    BasePricingModel? basePricing,
    OperatingHoursModel? operatingHours,
    PaymentsConfigModel? payments,
  }) {
    return TenantConfigData(
      logo: logo ?? this.logo,
      website: website ?? this.website,
      address: address ?? this.address,
      basePricing: basePricing ?? this.basePricing,
      operatingHours: operatingHours ?? this.operatingHours,
      payments: payments ?? this.payments,
    );
  }

  @override
  List<Object?> get props => [
    logo,
    website,
    address,
    basePricing,
    operatingHours,
    payments,
  ];
}

/// Configuration for payment gateway settings
class PaymentsConfigModel extends Equatable {
  /// Flag to enable/disable online payments for this tenant
  final bool enableOnlinePayments;
  final String? activeProvider;

  const PaymentsConfigModel({
    this.enableOnlinePayments = false,
    this.activeProvider,
  });

  factory PaymentsConfigModel.fromJson(Map<String, dynamic> json) {
    return PaymentsConfigModel(
      enableOnlinePayments: json['enableOnlinePayments'] as bool? ?? false,
      activeProvider: json['activeProvider']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableOnlinePayments': enableOnlinePayments,
      'activeProvider': activeProvider,
    };
  }

  PaymentsConfigModel copyWith({
    bool? enableOnlinePayments,
    String? activeProvider,
  }) {
    return PaymentsConfigModel(
      enableOnlinePayments: enableOnlinePayments ?? this.enableOnlinePayments,
      activeProvider: activeProvider ?? this.activeProvider,
    );
  }

  @override
  List<Object?> get props => [enableOnlinePayments, activeProvider];
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
  final List<DayScheduleModel>? schedule; // Array of day schedules
  // Legacy fields for backward compatibility
  final String? open; // Format: "HH:mm" (deprecated, use schedule)
  final String? close; // Format: "HH:mm" (deprecated, use schedule)
  final List<int>? daysOfWeek; // 0-6 (deprecated, use schedule)

  const OperatingHoursModel({
    this.schedule,
    this.open,
    this.close,
    this.daysOfWeek,
  });

  factory OperatingHoursModel.fromJson(Map<String, dynamic> json) {
    // Try new format first
    if (json['schedule'] != null && json['schedule'] is List) {
      return OperatingHoursModel(
        schedule: (json['schedule'] as List<dynamic>)
            .map((e) => DayScheduleModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
    }

    // Legacy format
    return OperatingHoursModel(
      open: json['open']?.toString(),
      close: json['close']?.toString(),
      daysOfWeek: (json['daysOfWeek'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    if (schedule != null && schedule!.isNotEmpty) {
      return {'schedule': schedule!.map((s) => s.toJson()).toList()};
    }

    // Legacy format
    final json = <String, dynamic>{};
    if (open != null) json['open'] = open;
    if (close != null) json['close'] = close;
    if (daysOfWeek != null) json['daysOfWeek'] = daysOfWeek;
    return json;
  }

  OperatingHoursModel copyWith({
    List<DayScheduleModel>? schedule,
    String? open,
    String? close,
    List<int>? daysOfWeek,
  }) {
    return OperatingHoursModel(
      schedule: schedule ?? this.schedule,
      open: open ?? this.open,
      close: close ?? this.close,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
    );
  }

  @override
  List<Object?> get props => [schedule, open, close, daysOfWeek];
}

class DayScheduleModel extends Equatable {
  final int dayOfWeek; // 0-6 (0 = Sunday, 6 = Saturday)
  final String open; // Format: "HH:mm"
  final String close; // Format: "HH:mm"

  const DayScheduleModel({
    required this.dayOfWeek,
    required this.open,
    required this.close,
  });

  factory DayScheduleModel.fromJson(Map<String, dynamic> json) {
    return DayScheduleModel(
      dayOfWeek: (json['dayOfWeek'] as num).toInt(),
      open: json['open'] as String,
      close: json['close'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'dayOfWeek': dayOfWeek, 'open': open, 'close': close};
  }

  DayScheduleModel copyWith({int? dayOfWeek, String? open, String? close}) {
    return DayScheduleModel(
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      open: open ?? this.open,
      close: close ?? this.close,
    );
  }

  @override
  List<Object?> get props => [dayOfWeek, open, close];
}

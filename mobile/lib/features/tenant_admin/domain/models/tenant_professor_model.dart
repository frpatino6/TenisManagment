/// Model for Professor in Tenant Admin context
class TenantProfessorModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> specialties;
  final double hourlyRate;
  final int experienceYears;
  final ProfessorPricing? pricing;
  final bool isActive;
  final DateTime? joinedAt;
  final int bookingsCount;
  final String authUserId;

  TenantProfessorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialties,
    required this.hourlyRate,
    required this.experienceYears,
    this.pricing,
    required this.isActive,
    this.joinedAt,
    required this.bookingsCount,
    required this.authUserId,
  });

  factory TenantProfessorModel.fromJson(Map<String, dynamic> json) {
    return TenantProfessorModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      specialties: (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      experienceYears: json['experienceYears'] as int? ?? 0,
      pricing: json['pricing'] != null
          ? ProfessorPricing.fromJson(json['pricing'] as Map<String, dynamic>)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      bookingsCount: json['bookingsCount'] as int? ?? 0,
      authUserId: json['authUserId'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'specialties': specialties,
      'hourlyRate': hourlyRate,
      'experienceYears': experienceYears,
      'pricing': pricing?.toJson(),
      'isActive': isActive,
      'joinedAt': joinedAt?.toIso8601String(),
      'bookingsCount': bookingsCount,
      'authUserId': authUserId,
    };
  }
}

class ProfessorPricing {
  final double individualClass;
  final double groupClass;
  final double courtRental;

  ProfessorPricing({
    required this.individualClass,
    required this.groupClass,
    required this.courtRental,
  });

  factory ProfessorPricing.fromJson(Map<String, dynamic> json) {
    return ProfessorPricing(
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

class InviteProfessorRequest {
  final String email;
  final ProfessorPricing? pricing;

  InviteProfessorRequest({
    required this.email,
    this.pricing,
  });

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      if (pricing != null) 'pricing': pricing!.toJson(),
    };
  }
}


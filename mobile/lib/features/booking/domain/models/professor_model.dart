class PricingConfig {
  final double individualClass;
  final double groupClass;
  final double courtRental;

  PricingConfig({
    required this.individualClass,
    required this.groupClass,
    required this.courtRental,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      individualClass: (json['individualClass'] as num).toDouble(),
      groupClass: (json['groupClass'] as num).toDouble(),
      courtRental: (json['courtRental'] as num).toDouble(),
    );
  }
}

class ProfessorBookingModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> specialties;
  final double hourlyRate;
  final PricingConfig pricing;
  final int experienceYears;
  final double rating;

  ProfessorBookingModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialties,
    required this.hourlyRate,
    required this.pricing,
    required this.experienceYears,
    required this.rating,
  });

  factory ProfessorBookingModel.fromJson(Map<String, dynamic> json) {
    return ProfessorBookingModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String? ?? '',
      specialties:
          (json['specialties'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      hourlyRate: (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      pricing: PricingConfig.fromJson(json['pricing'] as Map<String, dynamic>),
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
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
      'rating': rating,
    };
  }
}

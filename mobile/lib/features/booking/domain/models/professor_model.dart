class ProfessorBookingModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> specialties;
  final double hourlyRate;
  final int experienceYears;
  final double rating;

  ProfessorBookingModel({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.specialties,
    required this.hourlyRate,
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

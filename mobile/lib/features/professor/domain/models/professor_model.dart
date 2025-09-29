import 'package:equatable/equatable.dart';

class ProfessorModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> specialties;
  final double hourlyRate;
  final int experienceYears;
  final double rating;
  final int totalStudents;
  final int totalClasses;
  final double monthlyEarnings;
  final double weeklyEarnings;

  const ProfessorModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.specialties,
    required this.hourlyRate,
    required this.experienceYears,
    required this.rating,
    required this.totalStudents,
    required this.totalClasses,
    required this.monthlyEarnings,
    required this.weeklyEarnings,
  });

  factory ProfessorModel.fromJson(Map<String, dynamic> json) {
    return ProfessorModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'],
      specialties: List<String>.from(json['specialties'] ?? []),
      hourlyRate: (json['hourlyRate'] ?? 0).toDouble(),
      experienceYears: json['experienceYears'] ?? 0,
      rating: (json['rating'] ?? 0.0).toDouble(),
      totalStudents: json['totalStudents'] ?? 0,
      totalClasses: json['totalClasses'] ?? 0,
      monthlyEarnings: (json['monthlyEarnings'] ?? 0.0).toDouble(),
      weeklyEarnings: (json['weeklyEarnings'] ?? 0.0).toDouble(),
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
      'totalStudents': totalStudents,
      'totalClasses': totalClasses,
      'monthlyEarnings': monthlyEarnings,
      'weeklyEarnings': weeklyEarnings,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    specialties,
    hourlyRate,
    experienceYears,
    rating,
    totalStudents,
    totalClasses,
    monthlyEarnings,
    weeklyEarnings,
  ];
}

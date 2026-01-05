import 'package:equatable/equatable.dart';
import '../../../../core/validation/model_validator.dart';

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

  ProfessorModel({
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
  }) {
    // Validation in constructor
    assert(id.isNotEmpty, 'Professor id must not be empty');
    assert(name.isNotEmpty, 'Professor name must not be empty');
    ModelValidator.validateEmail(email, 'email');
    ModelValidator.validatePrice(hourlyRate);
    ModelValidator.validateNonNegativeInt(experienceYears, 'experienceYears');
    ModelValidator.validateRating(rating, 'rating');
    ModelValidator.validateNonNegativeInt(totalStudents, 'totalStudents');
    ModelValidator.validateNonNegativeInt(totalClasses, 'totalClasses');
    ModelValidator.validateNonNegative(monthlyEarnings, 'monthlyEarnings');
    ModelValidator.validateNonNegative(weeklyEarnings, 'weeklyEarnings');
  }

  factory ProfessorModel.fromJson(Map<String, dynamic> json) {
    final id = json['_id'] ?? json['id'] ?? '';
    final name = json['name'] ?? '';
    final email = json['email'] ?? '';
    
    return ProfessorModel(
      id: id,
      name: name,
      email: email,
      phone: json['phone'],
      specialties: List<String>.from(json['specialties'] ?? []),
      hourlyRate: ModelValidator.parseDouble(
        json['hourlyRate'],
        'hourlyRate',
        defaultValue: 0.0,
      ),
      experienceYears: ModelValidator.parseInt(
        json['experienceYears'],
        'experienceYears',
        defaultValue: 0,
      ),
      rating: ModelValidator.validateRating(
        ModelValidator.parseDouble(json['rating'], 'rating', defaultValue: 0.0),
        'rating',
      ),
      totalStudents: ModelValidator.parseInt(
        json['totalStudents'],
        'totalStudents',
        defaultValue: 0,
      ),
      totalClasses: ModelValidator.parseInt(
        json['totalClasses'],
        'totalClasses',
        defaultValue: 0,
      ),
      monthlyEarnings: ModelValidator.parseDouble(
        json['monthlyEarnings'],
        'monthlyEarnings',
        defaultValue: 0.0,
      ),
      weeklyEarnings: ModelValidator.parseDouble(
        json['weeklyEarnings'],
        'weeklyEarnings',
        defaultValue: 0.0,
      ),
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

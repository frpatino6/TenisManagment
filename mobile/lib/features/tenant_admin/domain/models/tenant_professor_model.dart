import 'package:equatable/equatable.dart';
import '../../../../core/validation/model_validator.dart';

/// Model for professor as seen by tenant admin
/// Includes tenant-specific information like pricing and isActive status
class TenantProfessorModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final List<String> specialties;
  final double hourlyRate;
  final int experienceYears;
  final Map<String, dynamic>? pricing; // Tenant-specific pricing
  final bool isActive;
  final DateTime? joinedAt;
  final int bookingsCount;
  final String? authUserId;

  const TenantProfessorModel({
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
    this.authUserId,
  });

  factory TenantProfessorModel.fromJson(Map<String, dynamic> json) {
    return TenantProfessorModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      specialties:
          (json['specialties'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
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
      pricing: json['pricing'] as Map<String, dynamic>?,
      isActive: json['isActive'] as bool? ?? false,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : null,
      bookingsCount: ModelValidator.parseInt(
        json['bookingsCount'],
        'bookingsCount',
        defaultValue: 0,
      ),
      authUserId: json['authUserId']?.toString(),
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
      'pricing': pricing,
      'isActive': isActive,
      'joinedAt': joinedAt?.toIso8601String(),
      'bookingsCount': bookingsCount,
      'authUserId': authUserId,
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
    pricing,
    isActive,
    joinedAt,
    bookingsCount,
    authUserId,
  ];
}

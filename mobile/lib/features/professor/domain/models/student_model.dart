import 'package:equatable/equatable.dart';

enum MembershipType {
  basic,
  premium,
}

class StudentModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final MembershipType membershipType;
  final double balance;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const StudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.membershipType,
    required this.balance,
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.fromJson(Map<String, dynamic> json) {
    return StudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      membershipType: MembershipType.values.firstWhere(
        (e) => e.name == json['membershipType'],
        orElse: () => MembershipType.basic,
      ),
      balance: (json['balance'] as num).toDouble(),
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
      'email': email,
      'phone': phone,
      'membershipType': membershipType.name,
      'balance': balance,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  StudentModel copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    MembershipType? membershipType,
    double? balance,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return StudentModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      membershipType: membershipType ?? this.membershipType,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get membershipTypeDisplayName {
    switch (membershipType) {
      case MembershipType.basic:
        return 'Básico';
      case MembershipType.premium:
        return 'Premium';
    }
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  @override
  List<Object?> get props => [
        id,
        name,
        email,
        phone,
        membershipType,
        balance,
        createdAt,
        updatedAt,
      ];
}

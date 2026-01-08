import 'package:tennis_management/features/tenant_admin/domain/models/tenant_booking_model.dart';

class TenantStudentModel {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String membershipType;
  final double balance;
  final bool isActive;
  final DateTime joinedAt;

  TenantStudentModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    required this.membershipType,
    required this.balance,
    required this.isActive,
    required this.joinedAt,
  });

  factory TenantStudentModel.fromJson(Map<String, dynamic> json) {
    return TenantStudentModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      membershipType: json['membershipType'] as String,
      balance: (json['balance'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'membershipType': membershipType,
      'balance': balance,
      'isActive': isActive,
      'joinedAt': joinedAt.toIso8601String(),
    };
  }
}

class TenantStudentDetailsModel extends TenantStudentModel {
  final List<TenantBookingModel> recentBookings;

  TenantStudentDetailsModel({
    required super.id,
    required super.name,
    required super.email,
    super.phone,
    required super.membershipType,
    required super.balance,
    required super.isActive,
    required super.joinedAt,
    required this.recentBookings,
  });

  factory TenantStudentDetailsModel.fromJson(Map<String, dynamic> json) {
    return TenantStudentDetailsModel(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
      membershipType: json['membershipType'] as String,
      balance: (json['balance'] as num).toDouble(),
      isActive: json['isActive'] as bool? ?? true,
      joinedAt: json['joinedAt'] != null
          ? DateTime.parse(json['joinedAt'] as String)
          : DateTime.now(),
      recentBookings:
          (json['recentBookings'] as List<dynamic>?)
              ?.map(
                (e) => TenantBookingModel.fromJson(e as Map<String, dynamic>),
              )
              .toList() ??
          [],
    );
  }
}

class StudentPagination {
  final int total;
  final int page;
  final int limit;
  final int pages;

  StudentPagination({
    required this.total,
    required this.page,
    required this.limit,
    required this.pages,
  });

  factory StudentPagination.fromJson(Map<String, dynamic> json) {
    return StudentPagination(
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
      pages: json['pages'] as int,
    );
  }
}

class TenantStudentsResponse {
  final List<TenantStudentModel> students;
  final StudentPagination pagination;

  TenantStudentsResponse({required this.students, required this.pagination});

  factory TenantStudentsResponse.fromJson(Map<String, dynamic> json) {
    return TenantStudentsResponse(
      students: (json['students'] as List<dynamic>)
          .map((e) => TenantStudentModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      pagination: StudentPagination.fromJson(
        json['pagination'] as Map<String, dynamic>,
      ),
    );
  }
}

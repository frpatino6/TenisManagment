class TenantBookingModel {
  final String id;
  final DateTime? date;
  final DateTime? startTime;
  final DateTime? endTime;
  final CourtInfo? court;
  final ProfessorInfo? professor;
  final StudentInfo student;
  final String
  serviceType; // 'individual_class' | 'group_class' | 'court_rental'
  final String status; // 'pending' | 'confirmed' | 'cancelled' | 'completed'
  final double price;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;

  TenantBookingModel({
    required this.id,
    this.date,
    this.startTime,
    this.endTime,
    this.court,
    this.professor,
    required this.student,
    required this.serviceType,
    required this.status,
    required this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TenantBookingModel.fromJson(Map<String, dynamic> json) {
    return TenantBookingModel(
      id: json['id'] as String,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : null,
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : null,
      court: json['court'] != null
          ? CourtInfo.fromJson(json['court'] as Map<String, dynamic>)
          : null,
      professor: json['professor'] != null
          ? ProfessorInfo.fromJson(json['professor'] as Map<String, dynamic>)
          : null,
      student: StudentInfo.fromJson(json['student'] as Map<String, dynamic>),
      serviceType: json['serviceType'] as String,
      status: json['status'] as String,
      price: (json['price'] as num).toDouble(),
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date?.toIso8601String(),
      'startTime': startTime?.toIso8601String(),
      'endTime': endTime?.toIso8601String(),
      'court': court?.toJson(),
      'professor': professor?.toJson(),
      'student': student.toJson(),
      'serviceType': serviceType,
      'status': status,
      'price': price,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isConfirmed => status == 'confirmed';
  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';

  bool get isCourtRental => serviceType == 'court_rental';
  bool get isIndividualClass => serviceType == 'individual_class';
  bool get isGroupClass => serviceType == 'group_class';
}

class CourtInfo {
  final String id;
  final String name;
  final String type;

  CourtInfo({required this.id, required this.name, required this.type});

  factory CourtInfo.fromJson(Map<String, dynamic> json) {
    return CourtInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type};
  }
}

class ProfessorInfo {
  final String id;
  final String name;
  final String email;

  ProfessorInfo({required this.id, required this.name, required this.email});

  factory ProfessorInfo.fromJson(Map<String, dynamic> json) {
    return ProfessorInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email};
  }
}

class StudentInfo {
  final String id;
  final String name;
  final String email;
  final String? phone;

  StudentInfo({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
  });

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    return StudentInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'email': email, 'phone': phone};
  }
}

class BookingPagination {
  final int page;
  final int limit;
  final int total;
  final int totalPages;

  BookingPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
  });

  factory BookingPagination.fromJson(Map<String, dynamic> json) {
    return BookingPagination(
      page: json['page'] as int,
      limit: json['limit'] as int,
      total: json['total'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
}

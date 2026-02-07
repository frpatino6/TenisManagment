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
  final String paymentStatus; // 'paid' | 'pending'
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
    required this.paymentStatus,
    required this.price,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TenantBookingModel.fromJson(Map<String, dynamic> json) {
    // API returns courtId, professorId, studentId due to populate in backend
    final serviceType = json['serviceType'] as String? ?? 'court_rental';
    final bookingDate = json['bookingDate'] as String?;
    final dateValue = json['date'] as String?;

    DateTime? parsedStartTime;
    if (json['startTime'] != null) {
      parsedStartTime = DateTime.parse(json['startTime'] as String);
    } else if (serviceType == 'court_rental' && bookingDate != null) {
      parsedStartTime = DateTime.parse(bookingDate);
    }

    DateTime? parsedEndTime;
    if (json['endTime'] != null) {
      parsedEndTime = DateTime.parse(json['endTime'] as String);
    }

    return TenantBookingModel(
      id: json['id'] as String? ?? json['_id'] as String,
      date: bookingDate != null
          ? DateTime.parse(bookingDate)
          : (dateValue != null ? DateTime.parse(dateValue) : null),
      startTime: parsedStartTime,
      endTime: parsedEndTime,
      court: (json['court'] != null)
          ? CourtInfo.fromJson(json['court'] as Map<String, dynamic>)
          : (json['courtId'] != null
                ? CourtInfo.fromJson(json['courtId'] as Map<String, dynamic>)
                : null),
      professor: (json['professor'] != null)
          ? ProfessorInfo.fromJson(json['professor'] as Map<String, dynamic>)
          : (json['professorId'] != null
                ? ProfessorInfo.fromJson(
                    json['professorId'] as Map<String, dynamic>,
                  )
                : null),
      student: (json['student'] ?? json['studentId']) != null
          ? StudentInfo.fromJson(
              (json['student'] ?? json['studentId']) as Map<String, dynamic>,
            )
          : StudentInfo(id: '', name: 'Estudiante no encontrado', email: '-'),
      serviceType: serviceType,
      status: json['status'] as String? ?? 'pending',
      paymentStatus: json['paymentStatus'] as String? ?? 'pending',
      price: (json['totalPrice'] ?? json['price'] ?? 0.0).toDouble(),
      notes: json['notes'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : DateTime.now(),
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
      id: json['id'] as String? ?? json['_id'] as String? ?? 'unk',
      name: json['name'] as String? ?? 'Sin nombre',
      type: json['type'] as String? ?? 'tennis',
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
      id: json['id'] as String? ?? json['_id'] as String? ?? 'unk',
      name: json['name'] as String? ?? 'Sin nombre',
      email: json['email'] as String? ?? '',
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

  static bool _isValidName(String value) {
    final t = value.trim();
    if (t.isEmpty) return false;
    if (t.contains('FontWeight') ||
        t.contains('TextStyle') ||
        t.contains('Color(') ||
        t.length > 80) {
      return false;
    }
    return true;
  }

  factory StudentInfo.fromJson(Map<String, dynamic> json) {
    final rawName = json['name'];
    String name = 'Sin nombre';
    if (rawName is String && rawName.trim().isNotEmpty) {
      name = _isValidName(rawName) ? rawName.trim() : 'Sin nombre';
    }
    if (name == 'Sin nombre') {
      final first = json['firstName'] as String?;
      final last = json['lastName'] as String?;
      if (first != null && first.trim().isNotEmpty) {
        name = last != null && last.trim().isNotEmpty
            ? '${first.trim()} ${last.trim()}'
            : first.trim();
        if (!_isValidName(name)) name = 'Sin nombre';
      } else if (last != null && last.trim().isNotEmpty) {
        name = _isValidName(last.trim()) ? last.trim() : 'Sin nombre';
      }
    }
    return StudentInfo(
      id: json['id'] as String? ?? json['_id'] as String? ?? 'unk',
      name: name,
      email: json['email'] as String? ?? '',
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
      total: json['total'] as int? ?? json['totalItems'] as int,
      totalPages: json['totalPages'] as int,
    );
  }

  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;

  // Compatibility with UI
  int get currentPage => page;
  int get totalItems => total;
  bool get hasNext => hasNextPage;
  bool get hasPrevious => hasPreviousPage;
}

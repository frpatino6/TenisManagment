/// Model for Tenant metrics
class TenantMetricsModel {
  final BookingsMetrics bookings;
  final PaymentsMetrics payments;
  final UsersMetrics users;
  final CourtsMetrics courts;
  final List<TopProfessor> topProfessors;

  TenantMetricsModel({
    required this.bookings,
    required this.payments,
    required this.users,
    required this.courts,
    required this.topProfessors,
  });

  factory TenantMetricsModel.fromJson(Map<String, dynamic> json) {
    return TenantMetricsModel(
      bookings: BookingsMetrics.fromJson(
          json['bookings'] as Map<String, dynamic>),
      payments: PaymentsMetrics.fromJson(
          json['payments'] as Map<String, dynamic>),
      users: UsersMetrics.fromJson(json['users'] as Map<String, dynamic>),
      courts: CourtsMetrics.fromJson(json['courts'] as Map<String, dynamic>),
      topProfessors: (json['topProfessors'] as List<dynamic>?)
              ?.map((e) =>
                  TopProfessor.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'bookings': bookings.toJson(),
      'payments': payments.toJson(),
      'users': users.toJson(),
      'courts': courts.toJson(),
      'topProfessors': topProfessors.map((e) => e.toJson()).toList(),
    };
  }
}

class BookingsMetrics {
  final int total;

  BookingsMetrics({required this.total});

  factory BookingsMetrics.fromJson(Map<String, dynamic> json) {
    return BookingsMetrics(
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total};
  }
}

class PaymentsMetrics {
  final int total;
  final double revenue;

  PaymentsMetrics({
    required this.total,
    required this.revenue,
  });

  factory PaymentsMetrics.fromJson(Map<String, dynamic> json) {
    return PaymentsMetrics(
      total: json['total'] as int? ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'revenue': revenue,
    };
  }
}

class UsersMetrics {
  final int professors;
  final int students;

  UsersMetrics({
    required this.professors,
    required this.students,
  });

  factory UsersMetrics.fromJson(Map<String, dynamic> json) {
    return UsersMetrics(
      professors: json['professors'] as int? ?? 0,
      students: json['students'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professors': professors,
      'students': students,
    };
  }
}

class CourtsMetrics {
  final int total;

  CourtsMetrics({required this.total});

  factory CourtsMetrics.fromJson(Map<String, dynamic> json) {
    return CourtsMetrics(
      total: json['total'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total};
  }
}

class TopProfessor {
  final String professorId;
  final String professorName;
  final int bookingsCount;

  TopProfessor({
    required this.professorId,
    required this.professorName,
    required this.bookingsCount,
  });

  factory TopProfessor.fromJson(Map<String, dynamic> json) {
    return TopProfessor(
      professorId: json['professorId'] as String,
      professorName: json['professorName'] as String,
      bookingsCount: json['bookingsCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professorId': professorId,
      'professorName': professorName,
      'bookingsCount': bookingsCount,
    };
  }
}


import 'package:equatable/equatable.dart';

class TenantMetricsModel extends Equatable {
  final BookingsMetrics bookings;
  final PaymentsMetrics payments;
  final UsersMetrics users;
  final CourtsMetrics courts;
  final List<TopProfessor> topProfessors;

  const TenantMetricsModel({
    required this.bookings,
    required this.payments,
    required this.users,
    required this.courts,
    required this.topProfessors,
  });

  factory TenantMetricsModel.fromJson(Map<String, dynamic> json) {
    return TenantMetricsModel(
      bookings: BookingsMetrics.fromJson(
        json['bookings'] as Map<String, dynamic>,
      ),
      payments: PaymentsMetrics.fromJson(
        json['payments'] as Map<String, dynamic>,
      ),
      users: UsersMetrics.fromJson(json['users'] as Map<String, dynamic>),
      courts: CourtsMetrics.fromJson(json['courts'] as Map<String, dynamic>),
      topProfessors:
          (json['topProfessors'] as List<dynamic>?)
              ?.map(
                (item) => TopProfessor.fromJson(item as Map<String, dynamic>),
              )
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
      'topProfessors': topProfessors.map((p) => p.toJson()).toList(),
    };
  }

  @override
  List<Object?> get props => [bookings, payments, users, courts, topProfessors];
}

class BookingsMetrics extends Equatable {
  final int total;

  const BookingsMetrics({required this.total});

  factory BookingsMetrics.fromJson(Map<String, dynamic> json) {
    return BookingsMetrics(total: (json['total'] as num?)?.toInt() ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'total': total};
  }

  @override
  List<Object?> get props => [total];
}

class PaymentsMetrics extends Equatable {
  final int total;
  final double revenue;

  const PaymentsMetrics({required this.total, required this.revenue});

  factory PaymentsMetrics.fromJson(Map<String, dynamic> json) {
    return PaymentsMetrics(
      total: (json['total'] as num?)?.toInt() ?? 0,
      revenue: (json['revenue'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'total': total, 'revenue': revenue};
  }

  @override
  List<Object?> get props => [total, revenue];
}

class UsersMetrics extends Equatable {
  final int professors;
  final int students;

  const UsersMetrics({required this.professors, required this.students});

  factory UsersMetrics.fromJson(Map<String, dynamic> json) {
    return UsersMetrics(
      professors: (json['professors'] as num?)?.toInt() ?? 0,
      students: (json['students'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'professors': professors, 'students': students};
  }

  @override
  List<Object?> get props => [professors, students];
}

class CourtsMetrics extends Equatable {
  final int total;

  const CourtsMetrics({required this.total});

  factory CourtsMetrics.fromJson(Map<String, dynamic> json) {
    return CourtsMetrics(total: (json['total'] as num?)?.toInt() ?? 0);
  }

  Map<String, dynamic> toJson() {
    return {'total': total};
  }

  @override
  List<Object?> get props => [total];
}

class TopProfessor extends Equatable {
  final String professorId;
  final String professorName;
  final int bookingsCount;

  const TopProfessor({
    required this.professorId,
    required this.professorName,
    required this.bookingsCount,
  });

  factory TopProfessor.fromJson(Map<String, dynamic> json) {
    return TopProfessor(
      professorId: json['professorId']?.toString() ?? '',
      professorName: json['professorName']?.toString() ?? '',
      bookingsCount: (json['bookingsCount'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professorId': professorId,
      'professorName': professorName,
      'bookingsCount': bookingsCount,
    };
  }

  @override
  List<Object?> get props => [professorId, professorName, bookingsCount];
}

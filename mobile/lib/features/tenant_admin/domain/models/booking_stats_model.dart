class BookingStatsModel {
  final int total;
  final double totalRevenue;
  final double averagePrice;
  final double walletRevenue;
  final double directRevenue;
  final List<RevenueTrendPoint> revenueTrend;
  final Map<String, StatusStats> byStatus;
  final Map<String, ServiceTypeStats> byServiceType;
  final List<CourtStats> topCourts;
  final List<ProfessorStats> topProfessors;

  BookingStatsModel({
    required this.total,
    required this.totalRevenue,
    required this.averagePrice,
    required this.walletRevenue,
    required this.directRevenue,
    required this.revenueTrend,
    required this.byStatus,
    required this.byServiceType,
    required this.topCourts,
    required this.topProfessors,
  });

  factory BookingStatsModel.fromJson(Map<String, dynamic> json) {
    return BookingStatsModel(
      total: json['total'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      averagePrice: (json['averagePrice'] as num).toDouble(),
      walletRevenue: (json['walletRevenue'] as num?)?.toDouble() ?? 0,
      directRevenue: (json['directRevenue'] as num?)?.toDouble() ?? 0,
      revenueTrend: (json['revenueTrend'] as List<dynamic>? ?? [])
          .map((e) => RevenueTrendPoint.fromJson(e as Map<String, dynamic>))
          .toList(),
      byStatus: (json['byStatus'] as Map<String, dynamic>).map(
        (key, value) =>
            MapEntry(key, StatusStats.fromJson(value as Map<String, dynamic>)),
      ),
      byServiceType: (json['byServiceType'] as Map<String, dynamic>).map(
        (key, value) => MapEntry(
          key,
          ServiceTypeStats.fromJson(value as Map<String, dynamic>),
        ),
      ),
      topCourts: (json['topCourts'] as List<dynamic>)
          .map((e) => CourtStats.fromJson(e as Map<String, dynamic>))
          .toList(),
      topProfessors: (json['topProfessors'] as List<dynamic>)
          .map((e) => ProfessorStats.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total': total,
      'totalRevenue': totalRevenue,
      'averagePrice': averagePrice,
      'walletRevenue': walletRevenue,
      'directRevenue': directRevenue,
      'revenueTrend': revenueTrend.map((e) => e.toJson()).toList(),
      'byStatus': byStatus.map((key, value) => MapEntry(key, value.toJson())),
      'byServiceType': byServiceType.map(
        (key, value) => MapEntry(key, value.toJson()),
      ),
      'topCourts': topCourts.map((e) => e.toJson()).toList(),
      'topProfessors': topProfessors.map((e) => e.toJson()).toList(),
    };
  }

  int get pendingCount => byStatus['pending']?.count ?? 0;
  int get confirmedCount => byStatus['confirmed']?.count ?? 0;
  int get cancelledCount => byStatus['cancelled']?.count ?? 0;
  int get completedCount => byStatus['completed']?.count ?? 0;

  double get pendingRevenue => byStatus['pending']?.revenue ?? 0;
  double get confirmedRevenue => byStatus['confirmed']?.revenue ?? 0;
  double get completedRevenue => byStatus['completed']?.revenue ?? 0;
}

class StatusStats {
  final int count;
  final double revenue;

  StatusStats({required this.count, required this.revenue});

  factory StatusStats.fromJson(Map<String, dynamic> json) {
    return StatusStats(
      count: json['count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'count': count, 'revenue': revenue};
  }
}

class RevenueTrendPoint {
  final String date;
  final double revenue;

  RevenueTrendPoint({required this.date, required this.revenue});

  factory RevenueTrendPoint.fromJson(Map<String, dynamic> json) {
    return RevenueTrendPoint(
      date: json['date'] as String,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'date': date, 'revenue': revenue};
  }
}

class ServiceTypeStats {
  final int count;
  final double revenue;

  ServiceTypeStats({required this.count, required this.revenue});

  factory ServiceTypeStats.fromJson(Map<String, dynamic> json) {
    return ServiceTypeStats(
      count: json['count'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {'count': count, 'revenue': revenue};
  }
}

class CourtStats {
  final String courtId;
  final String courtName;
  final String courtType;
  final int bookingsCount;
  final double revenue;

  CourtStats({
    required this.courtId,
    required this.courtName,
    required this.courtType,
    required this.bookingsCount,
    required this.revenue,
  });

  factory CourtStats.fromJson(Map<String, dynamic> json) {
    return CourtStats(
      courtId: json['courtId'] as String,
      courtName: json['courtName'] as String,
      courtType: json['courtType'] as String,
      bookingsCount: json['bookingsCount'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courtId': courtId,
      'courtName': courtName,
      'courtType': courtType,
      'bookingsCount': bookingsCount,
      'revenue': revenue,
    };
  }
}

class ProfessorStats {
  final String professorId;
  final String professorName;
  final int bookingsCount;
  final double revenue;

  ProfessorStats({
    required this.professorId,
    required this.professorName,
    required this.bookingsCount,
    required this.revenue,
  });

  factory ProfessorStats.fromJson(Map<String, dynamic> json) {
    return ProfessorStats(
      professorId: json['professorId'] as String,
      professorName: json['professorName'] as String,
      bookingsCount: json['bookingsCount'] as int,
      revenue: (json['revenue'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professorId': professorId,
      'professorName': professorName,
      'bookingsCount': bookingsCount,
      'revenue': revenue,
    };
  }
}

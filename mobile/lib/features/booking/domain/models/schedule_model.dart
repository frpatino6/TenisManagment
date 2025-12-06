/// Model for Schedule (class time slot) information
class ScheduleModel {
  final String id;
  final String? date;
  final DateTime startTime;
  final DateTime endTime;
  final String status;
  final String? notes;
  final bool isAvailable;
  final bool? isBlocked;

  ScheduleModel({
    required this.id,
    this.date,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.notes,
    required this.isAvailable,
    this.isBlocked,
  });

  factory ScheduleModel.fromJson(Map<String, dynamic> json) {
    return ScheduleModel(
      id: json['id'] as String,
      date: json['date'] as String?,
      startTime: json['startTime'] != null
          ? DateTime.parse(json['startTime'] as String)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.parse(json['endTime'] as String)
          : DateTime.now(),
      status: json['status'] as String? ?? 'pending',
      notes: json['notes'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isBlocked: json['isBlocked'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
      'notes': notes,
      'isAvailable': isAvailable,
      'isBlocked': isBlocked,
    };
  }

  /// Format time range as "HH:mm - HH:mm"
  String get timeRange {
    final start = '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
    final end = '${endTime.hour.toString().padLeft(2, '0')}:${endTime.minute.toString().padLeft(2, '0')}';
    return '$start - $end';
  }

  /// Format date as "DD/MM/YYYY"
  String get formattedDate {
    return '${startTime.day.toString().padLeft(2, '0')}/${startTime.month.toString().padLeft(2, '0')}/${startTime.year}';
  }

  /// Format day name (e.g., "Lun", "Mar")
  String get dayName {
    const days = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    return days[startTime.weekday % 7];
  }
}

/// Model for schedules grouped by tenant (center)
class TenantSchedulesGroup {
  final String tenantId;
  final String tenantName;
  final String tenantSlug;
  final String? tenantLogo;
  final List<ScheduleModel> schedules;

  TenantSchedulesGroup({
    required this.tenantId,
    required this.tenantName,
    required this.tenantSlug,
    this.tenantLogo,
    required this.schedules,
  });

  factory TenantSchedulesGroup.fromJson(Map<String, dynamic> json) {
    return TenantSchedulesGroup(
      tenantId: json['tenantId'] as String,
      tenantName: json['tenantName'] as String,
      tenantSlug: json['tenantSlug'] as String,
      tenantLogo: json['tenantLogo'] as String?,
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((s) => ScheduleModel.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'tenantId': tenantId,
      'tenantName': tenantName,
      'tenantSlug': tenantSlug,
      'tenantLogo': tenantLogo,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    };
  }
}

/// Model for professor schedules response
class ProfessorSchedulesResponse {
  final String professorId;
  final String professorName;
  final List<TenantSchedulesGroup> schedules;

  ProfessorSchedulesResponse({
    required this.professorId,
    required this.professorName,
    required this.schedules,
  });

  factory ProfessorSchedulesResponse.fromJson(Map<String, dynamic> json) {
    return ProfessorSchedulesResponse(
      professorId: json['professorId'] as String,
      professorName: json['professorName'] as String,
      schedules: (json['schedules'] as List<dynamic>?)
              ?.map((s) => TenantSchedulesGroup.fromJson(s as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'professorId': professorId,
      'professorName': professorName,
      'schedules': schedules.map((s) => s.toJson()).toList(),
    };
  }
}


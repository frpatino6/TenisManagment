class ProfessorScheduleModel {
  final String id;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? type;
  final bool isAvailable;
  final bool isBlocked;
  final String? blockReason;
  final String? status;
  final double? price;
  final String? studentName;
  final String? studentEmail;
  final String? courtId;

  ProfessorScheduleModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.isAvailable,
    required this.isBlocked,
    this.blockReason,
    this.status,
    this.price,
    this.studentName,
    this.studentEmail,
    this.courtId,
  });

  factory ProfessorScheduleModel.fromJson(Map<String, dynamic> json) {
    // Parse dates as UTC - the backend sends UTC times that represent the local time selected
    // When user selects 10:00 AM, backend stores 10:00 UTC (not 15:00 UTC)
    // So we parse as UTC and display as UTC (no conversion needed)
    final dateStr = json['date'] as String;
    final startTimeStr = json['startTime'] as String;
    final endTimeStr = json['endTime'] as String;

    // Parse as UTC explicitly
    final date = DateTime.parse(dateStr).toUtc();
    final startTime = DateTime.parse(startTimeStr).toUtc();
    final endTime = DateTime.parse(endTimeStr).toUtc();

    return ProfessorScheduleModel(
      id: json['id'] as String,
      date: date,
      startTime: startTime,
      endTime: endTime,
      type: json['type'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockReason: json['blockReason'] as String?,
      status: json['status'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      studentName: json['studentName'] as String?,
      studentEmail: json['studentEmail'] as String?,
      courtId: json['courtId'] as String?,
    );
  }

  String get formattedDate {
    // The date is stored in UTC but represents the local date selected
    // So we display it directly as UTC date (no conversion needed)
    final months = [
      '',
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return '${date.day} ${months[date.month]} ${date.year}';
  }

  String get formattedTimeRange {
    // The times are stored in UTC but represent the local time the user selected
    // So we display them directly as UTC hours (no conversion to local)
    // Example: User selected 10:00 AM -> stored as 10:00 UTC -> display as 10:00
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pendiente';
      case 'confirmed':
        return 'Confirmada';
      case 'cancelled':
        return 'Cancelada';
      case 'completed':
        return 'Completada';
      default:
        return status ?? 'Pendiente';
    }
  }
}

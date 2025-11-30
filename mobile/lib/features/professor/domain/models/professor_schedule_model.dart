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

  ProfessorScheduleModel({
    required this.id,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.type,
    required this.isAvailable,
    required this.isBlocked,
    this.blockReason,
    this.status,
    this.price,
    this.studentName,
    this.studentEmail,
  });

  factory ProfessorScheduleModel.fromJson(Map<String, dynamic> json) {
    return ProfessorScheduleModel(
      id: json['id'] as String,
      date: DateTime.parse(json['date'] as String),
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      type: json['type'] as String?,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockReason: json['blockReason'] as String?,
      status: json['status'] as String?,
      price: (json['price'] as num?)?.toDouble(),
      studentName: json['studentName'] as String?,
      studentEmail: json['studentEmail'] as String?,
    );
  }

  String get formattedDate {
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

    final localStart = startTime.toLocal();
    final localEnd = endTime.toLocal();

    final startHour = localStart.hour.toString().padLeft(2, '0');
    final startMinute = localStart.minute.toString().padLeft(2, '0');
    final endHour = localEnd.hour.toString().padLeft(2, '0');
    final endMinute = localEnd.minute.toString().padLeft(2, '0');
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

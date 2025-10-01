class AvailableScheduleModel {
  final String id;
  final String professorId;
  final DateTime startTime;
  final DateTime endTime;
  final String status;

  AvailableScheduleModel({
    required this.id,
    required this.professorId,
    required this.startTime,
    required this.endTime,
    required this.status,
  });

  factory AvailableScheduleModel.fromJson(Map<String, dynamic> json) {
    return AvailableScheduleModel(
      id: json['id'] as String,
      professorId: json['professorId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      status: json['status'] as String? ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professorId': professorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'status': status,
    };
  }

  String get formattedDate {
    final localStart = startTime.toLocal();
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
    return '${localStart.day} ${months[localStart.month]}';
  }

  String get formattedTimeRange {
    // Convert to local time explicitly
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
}

class AvailableScheduleModel {
  final String id;
  final String professorId;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final double price;
  final String status;

  AvailableScheduleModel({
    required this.id,
    required this.professorId,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.price,
    required this.status,
  });

  factory AvailableScheduleModel.fromJson(Map<String, dynamic> json) {
    return AvailableScheduleModel(
      id: json['id'] as String,
      professorId: json['professorId'] as String,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      type: json['type'] as String? ?? 'lesson',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'available',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professorId': professorId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type,
      'price': price,
      'status': status,
    };
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
    return '${startTime.day} ${months[startTime.month]}';
  }

  String get formattedTimeRange {
    final startHour = startTime.hour.toString().padLeft(2, '0');
    final startMinute = startTime.minute.toString().padLeft(2, '0');
    final endHour = endTime.hour.toString().padLeft(2, '0');
    final endMinute = endTime.minute.toString().padLeft(2, '0');
    return '$startHour:$startMinute - $endHour:$endMinute';
  }

  int get durationInMinutes {
    return endTime.difference(startTime).inMinutes;
  }
}

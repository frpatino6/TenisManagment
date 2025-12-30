import 'package:equatable/equatable.dart';

class ClassScheduleModel extends Equatable {
  final String id;
  final String studentName;
  final String studentId;
  final DateTime startTime;
  final DateTime endTime;
  final String type;
  final String status;
  final String? notes;
  final double price;

  const ClassScheduleModel({
    required this.id,
    required this.studentName,
    required this.studentId,
    required this.startTime,
    required this.endTime,
    required this.type,
    required this.status,
    this.notes,
    required this.price,
  });

  factory ClassScheduleModel.fromJson(Map<String, dynamic> json) {
    // Parse dates as UTC - the backend sends UTC times that represent the local time selected
    // When user selects 10:00 AM, backend stores 10:00 UTC (not 15:00 UTC)
    // So we parse as UTC and display as UTC (no conversion needed)
    final startTimeStr = json['startTime'] as String? ?? '';
    final endTimeStr = json['endTime'] as String? ?? '';
    
    final startTime = startTimeStr.isNotEmpty 
        ? DateTime.parse(startTimeStr).toUtc()
        : DateTime.now().toUtc();
    final endTime = endTimeStr.isNotEmpty
        ? DateTime.parse(endTimeStr).toUtc()
        : DateTime.now().toUtc();
    
    return ClassScheduleModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentName: json['studentName'] ?? '',
      studentId: json['studentId'] ?? '',
      startTime: startTime,
      endTime: endTime,
      type: json['serviceType'] ?? json['type'] ?? 'Clase individual',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentName': studentName,
      'studentId': studentId,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'type': type,
      'status': status,
      'notes': notes,
      'price': price,
    };
  }

  String get formattedTime {
    // The times are stored in UTC but represent the local time the user selected
    // So we display them directly as UTC hours (no conversion to local)
    // Example: User selected 10:00 AM -> stored as 10:00 UTC -> display as 10:00 AM
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${startTime.hour < 12 ? 'AM' : 'PM'}';
  }

  String get formattedDate {
    // The date is stored in UTC but represents the local date selected
    // So we display it directly as UTC date (no conversion needed)
    return '${startTime.day}/${startTime.month}/${startTime.year}';
  }

  Duration get duration {
    return endTime.difference(startTime);
  }

  String get formattedDuration {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  @override
  List<Object?> get props => [
    id,
    studentName,
    studentId,
    startTime,
    endTime,
    type,
    status,
    notes,
    price,
  ];
}

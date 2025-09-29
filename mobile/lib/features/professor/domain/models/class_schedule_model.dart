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
    return ClassScheduleModel(
      id: json['_id'] ?? json['id'] ?? '',
      studentName: json['studentName'] ?? '',
      studentId: json['studentId'] ?? '',
      startTime: DateTime.parse(json['startTime']),
      endTime: DateTime.parse(json['endTime']),
      type: json['type'] ?? 'Clase individual',
      status: json['status'] ?? 'pending',
      notes: json['notes'],
      price: (json['price'] ?? 0.0).toDouble(),
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
    final hour = startTime.hour.toString().padLeft(2, '0');
    final minute = startTime.minute.toString().padLeft(2, '0');
    return '$hour:$minute ${startTime.hour < 12 ? 'AM' : 'PM'}';
  }

  String get formattedDate {
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

import 'package:equatable/equatable.dart';

class StudentSummaryModel extends Equatable {
  final String id;
  final String name;
  final String email;
  final String level;
  final String? nextClassTime;
  final String? nextClassDate;
  final int totalClasses;
  final double progress;

  const StudentSummaryModel({
    required this.id,
    required this.name,
    required this.email,
    required this.level,
    this.nextClassTime,
    this.nextClassDate,
    required this.totalClasses,
    required this.progress,
  });

  factory StudentSummaryModel.fromJson(Map<String, dynamic> json) {
    return StudentSummaryModel(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      level: json['level'] ?? 'Principiante',
      nextClassTime: json['nextClassTime'],
      nextClassDate: json['nextClassDate'],
      totalClasses: json['totalClasses'] ?? 0,
      progress: (json['progress'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'level': level,
      'nextClassTime': nextClassTime,
      'nextClassDate': nextClassDate,
      'totalClasses': totalClasses,
      'progress': progress,
    };
  }

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    level,
    nextClassTime,
    nextClassDate,
    totalClasses,
    progress,
  ];
}

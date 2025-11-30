class BookingModel {
  final String id;
  final ProfessorBookingModel professor;
  final AvailableScheduleModel schedule;
  final String serviceType;
  final double price;
  final String status;
  final String createdAt;

  BookingModel({
    required this.id,
    required this.professor,
    required this.schedule,
    required this.serviceType,
    required this.price,
    required this.status,
    required this.createdAt,
  });

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    return BookingModel(
      id: json['id'] as String,
      professor: json['professor'] != null
          ? ProfessorBookingModel.fromJson(
              json['professor'] as Map<String, dynamic>,
            )
          : ProfessorBookingModel(
              id: '',
              name: 'Profesor no disponible',
              email: '',
              specialties: [],
              pricing: {},
            ),
      schedule: json['schedule'] != null
          ? AvailableScheduleModel.fromJson(
              json['schedule'] as Map<String, dynamic>,
            )
          : AvailableScheduleModel(
              id: '',
              professorId: '',
              startTime: DateTime.now().toIso8601String(),
              endTime: DateTime.now().toIso8601String(),
              type: 'individual_class',
              price: 0,
              status: 'pending',
            ),
      serviceType: json['serviceType'] as String? ?? 'individual_class',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt: json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professor': professor.toJson(),
      'schedule': schedule.toJson(),
      'serviceType': serviceType,
      'price': price,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class ProfessorBookingModel {
  final String id;
  final String name;
  final String email;
  final List<String> specialties;
  final Map<String, dynamic> pricing;

  ProfessorBookingModel({
    required this.id,
    required this.name,
    required this.email,
    required this.specialties,
    required this.pricing,
  });

  factory ProfessorBookingModel.fromJson(Map<String, dynamic> json) {
    return ProfessorBookingModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Profesor no disponible',
      email: json['email'] as String? ?? '',
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : [],
      pricing: json['pricing'] as Map<String, dynamic>? ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'specialties': specialties,
      'pricing': pricing,
    };
  }
}

class AvailableScheduleModel {
  final String id;
  final String professorId;
  final String startTime;
  final String endTime;
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
      id: json['id'] as String? ?? '',
      professorId: json['professorId'] as String? ?? '',
      startTime: json['startTime'] as String? ?? DateTime.now().toIso8601String(),
      endTime: json['endTime'] as String? ?? DateTime.now().toIso8601String(),
      type: json['type'] as String? ?? 'individual_class',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professorId': professorId,
      'startTime': startTime,
      'endTime': endTime,
      'type': type,
      'price': price,
      'status': status,
    };
  }
}

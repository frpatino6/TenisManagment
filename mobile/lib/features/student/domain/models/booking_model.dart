class BookingModel {
  final String id;
  final ProfessorBookingModel professor;
  final AvailableScheduleModel schedule;
  final CourtBookingModel? court;
  final String serviceType;
  final double price;
  final String status;
  final String createdAt;

  BookingModel({
    required this.id,
    required this.professor,
    required this.schedule,
    this.court,
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
      court: json['court'] != null
          ? CourtBookingModel.fromJson(
              json['court'] as Map<String, dynamic>,
            )
          : null,
      serviceType: json['serviceType'] as String? ?? 'individual_class',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      status: json['status'] as String? ?? 'pending',
      createdAt:
          json['createdAt'] as String? ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'professor': professor.toJson(),
      'schedule': schedule.toJson(),
      'court': court?.toJson(),
      'serviceType': serviceType,
      'price': price,
      'status': status,
      'createdAt': createdAt,
    };
  }
}

class CourtBookingModel {
  final String id;
  final String name;
  final String type;
  final double price;

  CourtBookingModel({
    required this.id,
    required this.name,
    required this.type,
    required this.price,
  });

  factory CourtBookingModel.fromJson(Map<String, dynamic> json) {
    return CourtBookingModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Cancha',
      type: json['type'] as String? ?? 'tennis',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'price': price,
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
    // Safely parse startTime and endTime, handling empty strings
    String parseTime(String? timeStr) {
      if (timeStr == null || timeStr.isEmpty) {
        return DateTime.now().toIso8601String();
      }
      try {
        // Validate that it's a valid ISO string
        DateTime.parse(timeStr);
        return timeStr;
      } catch (e) {
        // If parsing fails, return current time
        return DateTime.now().toIso8601String();
      }
    }

    return AvailableScheduleModel(
      id: json['id'] as String? ?? '',
      professorId: json['professorId'] as String? ?? '',
      startTime: parseTime(json['startTime'] as String?),
      endTime: parseTime(json['endTime'] as String?),
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

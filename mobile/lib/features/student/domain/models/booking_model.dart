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
      professor: ProfessorBookingModel.fromJson(
        json['professor'] as Map<String, dynamic>,
      ),
      schedule: AvailableScheduleModel.fromJson(
        json['schedule'] as Map<String, dynamic>,
      ),
      serviceType: json['serviceType'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: json['createdAt'] as String,
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
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      specialties: List<String>.from(json['specialties'] as List),
      pricing: json['pricing'] as Map<String, dynamic>,
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
      id: json['id'] as String,
      professorId: json['professorId'] as String,
      startTime: json['startTime'] as String,
      endTime: json['endTime'] as String,
      type: json['type'] as String,
      price: (json['price'] as num).toDouble(),
      status: json['status'] as String,
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

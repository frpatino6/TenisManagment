import '../../../../core/validation/model_validator.dart';

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
  }) {
    // Validation in constructor
    assert(id.isNotEmpty, 'Booking id must not be empty');
    assert(
      ['individual_class', 'group_class', 'court_rental'].contains(serviceType),
      'Service type must be individual_class, group_class, or court_rental',
    );
    assert(
      ['pending', 'confirmed', 'cancelled', 'completed'].contains(status),
      'Status must be pending, confirmed, cancelled, or completed',
    );
    ModelValidator.validatePrice(price);
  }

  factory BookingModel.fromJson(Map<String, dynamic> json) {
    final id = json['id'] as String;
    final price = ModelValidator.parseDouble(
      json['price'],
      'price',
      defaultValue: 0.0,
    );

    return BookingModel(
      id: id,
      professor: json['professor'] != null
          ? ProfessorBookingModel.fromJson(
              json['professor'] as Map<String, dynamic>,
            )
          : ProfessorBookingModel(
              id: '',
              name: 'Profesor no disponible',
              email: '',
              specialties: [],
              pricing: PricingConfig(
                individualClass: 0,
                groupClass: 0,
                courtRental: 0,
              ),
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
          ? CourtBookingModel.fromJson(json['court'] as Map<String, dynamic>)
          : null,
      serviceType: json['serviceType'] as String? ?? 'individual_class',
      price: price,
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
  }) {
    // Validation in constructor
    assert(
      ['tennis', 'padel', 'multi'].contains(type),
      'Court type must be tennis, padel, or multi',
    );
    ModelValidator.validatePrice(price);
  }

  factory CourtBookingModel.fromJson(Map<String, dynamic> json) {
    final price = ModelValidator.parseDouble(
      json['price'],
      'price',
      defaultValue: 0.0,
    );

    return CourtBookingModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Cancha',
      type: json['type'] as String? ?? 'tennis',
      price: price,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'type': type, 'price': price};
  }
}

class PricingConfig {
  final double individualClass;
  final double groupClass;
  final double courtRental;

  PricingConfig({
    required this.individualClass,
    required this.groupClass,
    required this.courtRental,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      individualClass:
          (json['individual_class'] ?? json['individualClass'] ?? 0.0)
              .toDouble(),
      groupClass: (json['group_class'] ?? json['groupClass'] ?? 0.0).toDouble(),
      courtRental: (json['court_rental'] ?? json['courtRental'] ?? 0.0)
          .toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'individual_class': individualClass,
      'group_class': groupClass,
      'court_rental': courtRental,
    };
  }
}

class ProfessorBookingModel {
  final String id;
  final String name;
  final String email;
  final String phone;
  final List<String> specialties;
  final PricingConfig pricing;

  final double rating;
  final int experienceYears;
  final double hourlyRate;

  ProfessorBookingModel({
    required this.id,
    required this.name,
    required this.email,
    this.phone = '',
    this.rating = 0.0,
    this.experienceYears = 0,
    this.hourlyRate = 0.0,
    required this.specialties,
    required this.pricing,
  });

  factory ProfessorBookingModel.fromJson(Map<String, dynamic> json) {
    return ProfessorBookingModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Profesor no disponible',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      experienceYears: json['experienceYears'] as int? ?? 0,
      hourlyRate:
          (json['hourlyRate'] as num?)?.toDouble() ??
          (json['pricing']?['individual_class'] as num?)?.toDouble() ??
          0.0,
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'] as List)
          : [],
      pricing: json['pricing'] != null
          ? PricingConfig.fromJson(json['pricing'] as Map<String, dynamic>)
          : PricingConfig(individualClass: 0, groupClass: 0, courtRental: 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'rating': rating,
      'experienceYears': experienceYears,
      'hourlyRate': hourlyRate,
      'specialties': specialties,
      'pricing': pricing.toJson(),
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
    required dynamic startTime,
    required dynamic endTime,
    this.type = 'individual_class',
    this.price = 0.0,
    this.status = 'available',
  }) : startTime = startTime is DateTime
           ? startTime.toIso8601String()
           : startTime.toString(),
       endTime = endTime is DateTime
           ? endTime.toIso8601String()
           : endTime.toString();

  DateTime get startDateTime => DateTime.parse(startTime);
  DateTime get endDateTime => DateTime.parse(endTime);

  String get formattedDate {
    try {
      final date = DateTime.parse(startTime);
      final months = [
        'enero',
        'febrero',
        'marzo',
        'abril',
        'mayo',
        'junio',
        'julio',
        'agosto',
        'septiembre',
        'octubre',
        'noviembre',
        'diciembre',
      ];
      final days = [
        'lunes',
        'martes',
        'miércoles',
        'jueves',
        'viernes',
        'sábado',
        'domingo',
      ];
      return '${days[date.weekday - 1]}, ${date.day} de ${months[date.month - 1]}';
    } catch (e) {
      return startTime;
    }
  }

  String get formattedTimeRange {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      String format(DateTime dt) {
        final hour = dt.hour > 12
            ? dt.hour - 12
            : (dt.hour == 0 ? 12 : dt.hour);
        final ampm = dt.hour >= 12 ? 'PM' : 'AM';
        final minute = dt.minute.toString().padLeft(2, '0');
        return '$hour:$minute $ampm';
      }

      return '${format(start)} - ${format(end)}';
    } catch (e) {
      return '$startTime - $endTime';
    }
  }

  int get durationInMinutes {
    try {
      final start = DateTime.parse(startTime);
      final end = DateTime.parse(endTime);
      return end.difference(start).inMinutes;
    } catch (e) {
      return 60; // Default to 60 minutes if parsing fails
    }
  }

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

    final price = ModelValidator.parseDouble(
      json['price'],
      'price',
      defaultValue: 0.0,
    );

    return AvailableScheduleModel(
      id: json['id'] as String? ?? '',
      professorId: json['professorId'] as String? ?? '',
      startTime: parseTime(json['startTime'] as String?),
      endTime: parseTime(json['endTime'] as String?),
      type: json['type'] as String? ?? 'individual_class',
      price: price,
      status: json['status'] as String? ?? 'available',
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

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../models/professor_model.dart';
import '../models/student_summary_model.dart';
import '../models/class_schedule_model.dart';

/// Service responsible for professor-related operations
/// Handles professor dashboard data, schedules, and student management
/// Manages API communication for professor-specific endpoints
class ProfessorService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Retrieves professor information and dashboard data
  /// Returns [ProfessorModel] with complete professor details
  /// Throws [Exception] if authentication fails or API request fails
  Future<ProfessorModel> getProfessorInfo() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh

      final url = '$_baseUrl/professor-dashboard/me';

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfessorModel.fromJson(data);
      } else {
        throw Exception(
          'Error al obtener información del profesor: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<List<StudentSummaryModel>> getStudents() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/students'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> studentsJson = data['items'] ?? [];
        return studentsJson
            .map((json) => StudentSummaryModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener estudiantes: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<List<ClassScheduleModel>> getTodaySchedule() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/today'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] ?? [];
        return classesJson
            .map((json) => ClassScheduleModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener horarios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<List<ClassScheduleModel>> getScheduleByDate(DateTime date) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);


      final localDate = DateTime(date.year, date.month, date.day);
      final dateStr =
          '${localDate.year}-${localDate.month.toString().padLeft(2, '0')}-${localDate.day.toString().padLeft(2, '0')}';

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedule/by-date?date=$dateStr',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] ?? [];
        return classesJson
            .map((json) => ClassScheduleModel.fromJson(json))
            .toList();
      } else {
        throw Exception('Error al obtener horarios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<List<ClassScheduleModel>> getWeekSchedule() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/week'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> classesJson = data['items'] ?? [];
        return classesJson
            .map((json) => ClassScheduleModel.fromJson(json))
            .toList();
      } else {
        throw Exception(
          'Error al obtener horarios de la semana: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<Map<String, dynamic>> getEarningsStats() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/earnings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al obtener estadísticas de ganancias: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<ProfessorModel> updateProfile({
    required String name,
    required String phone,
    required List<String> specialties,
    required double hourlyRate,
    required int experienceYears,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'name': name,
          'phone': phone,
          'specialties': specialties,
          'hourlyRate': hourlyRate,
          'experienceYears': experienceYears,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfessorModel.fromJson(data);
      } else {
        throw Exception('Error al actualizar perfil: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<void> confirmClass(String classId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/$classId/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode != 200) {
        throw Exception('Error al confirmar clase: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }


  Future<void> cancelClass(String classId, String reason) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true); // Force refresh
      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/schedule/$classId/cancel'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode != 200) {
        throw Exception('Error al cancelar clase: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Create a new schedule
  Future<Map<String, dynamic>> createSchedule({
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
    String? tenantId, // Optional tenantId - if not provided, backend will use first active tenant
  }) async {
    try {
      print('📅 [ProfessorService] Creating schedule...');
      print('📅 [ProfessorService] Date: ${date.toIso8601String()}');
      print('📅 [ProfessorService] StartTime: ${startTime.toIso8601String()}');
      print('📅 [ProfessorService] EndTime: ${endTime.toIso8601String()}');
      print('📅 [ProfessorService] TenantId: $tenantId');
      
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      // Build request body with optional tenantId
      final requestBody = <String, dynamic>{
        'date': date.toIso8601String(),
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      };
      
      // Add tenantId if provided
      if (tenantId != null && tenantId.isNotEmpty) {
        requestBody['tenantId'] = tenantId;
      }

      print('📅 [ProfessorService] Request body: ${json.encode(requestBody)}');
      print('📅 [ProfessorService] URL: $_baseUrl/professor-dashboard/schedules');

      final response = await http.post(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(requestBody),
      );

      print('📅 [ProfessorService] Response status: ${response.statusCode}');
      print('📅 [ProfessorService] Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final errorBody = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage = errorBody?['error'] as String? ?? 
                            errorBody?['message'] as String? ?? 
                            'Error al crear horario: ${response.statusCode}';
        throw Exception(errorMessage);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get all schedules for the professor
  Future<List<dynamic>> getMySchedules() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items;
      } else {
        throw Exception('Error al obtener horarios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Delete a schedule
  Future<void> deleteSchedule(String scheduleId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.delete(
        Uri.parse('$_baseUrl/professor-dashboard/schedules/$scheduleId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al eliminar horario');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Block a schedule
  Future<void> blockSchedule(String scheduleId, String reason) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.put(
        Uri.parse('$_baseUrl/professor-dashboard/schedules/$scheduleId/block'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'reason': reason}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al bloquear horario');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Unblock a schedule
  Future<void> unblockSchedule(String scheduleId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedules/$scheduleId/unblock',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al desbloquear horario');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Mark a class as completed
  Future<void> completeClass(String scheduleId, {double? paymentAmount}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedules/$scheduleId/complete',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'paymentAmount': paymentAmount}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al completar clase');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel a booking
  Future<void> cancelBooking(
    String scheduleId, {
    String? reason,
    double? penaltyAmount,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.put(
        Uri.parse(
          '$_baseUrl/professor-dashboard/schedules/$scheduleId/cancel-booking',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'reason': reason, 'penaltyAmount': penaltyAmount}),
      );

      if (response.statusCode != 200) {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al cancelar reserva');
      }
    } catch (e) {
      rethrow;
    }
  }
}

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/professor_model.dart';
import '../models/student_summary_model.dart';
import '../models/class_schedule_model.dart';

class ProfessorService {
  static const String _baseUrl = 'http://192.168.18.6:3000/api';

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Obtener información del profesor
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

  // Obtener lista de estudiantes del profesor
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

  // Obtener horarios de hoy
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

      // Format date as YYYY-MM-DD (use local date, not UTC)
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

  // Obtener horarios de la semana
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

  // Obtener estadísticas de ganancias
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

  // Actualizar perfil del profesor
  Future<ProfessorModel> updateProfile({
    required String name,
    required String phone,
    required List<String> specialties,
    required double hourlyRate,
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

  // Confirmar clase
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

  // Cancelar clase
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
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final response = await http.post(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({
          'date': date.toIso8601String(),
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Error al crear horario: ${response.statusCode}');
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

      debugPrint('📅 Calling getMySchedules...');

      final response = await http.get(
        Uri.parse('$_baseUrl/professor-dashboard/schedules'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;
        debugPrint('Received ${items.length} schedules from backend');

        // Log a booked schedule if exists
        final bookedSchedules = items
            .where((s) => s['studentName'] != null)
            .toList();
        if (bookedSchedules.isNotEmpty) {
          debugPrint('Example booked schedule: ${bookedSchedules.first}');
        }

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
  Future<void> cancelBooking(String scheduleId, {String? reason}) async {
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
        body: json.encode({'reason': reason}),
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

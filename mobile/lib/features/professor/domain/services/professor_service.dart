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
        debugPrint('No Firebase user found');
        throw Exception('Usuario no autenticado');
      }

      debugPrint('Firebase user found: ${user.uid}');
      final idToken = await user.getIdToken(true); // Force refresh
      debugPrint('ID Token obtained, length: ${idToken?.length ?? 0}');

      final url = '$_baseUrl/professor-dashboard/me';
      debugPrint('Making request to: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return ProfessorModel.fromJson(data);
      } else {
        throw Exception(
          'Error al obtener información del profesor: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error getting professor info: $e');
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
      debugPrint('Error getting students: $e');
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
      debugPrint('Error getting today schedule: $e');
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
      debugPrint('Error getting week schedule: $e');
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
      debugPrint('Error getting earnings stats: $e');
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
      debugPrint('Error updating profile: $e');
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
      debugPrint('Error confirming class: $e');
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
      debugPrint('Error canceling class: $e');
      rethrow;
    }
  }
}

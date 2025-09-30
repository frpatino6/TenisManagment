import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/professor_model.dart';
import '../models/available_schedule_model.dart';

class BookingService {
  final String _baseUrl = 'http://192.168.18.6:3000/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get list of all professors
  Future<List<ProfessorBookingModel>> getProfessors() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      debugPrint('Getting professors list');

      final response = await http.get(
        Uri.parse('$_baseUrl/student-dashboard/professors'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) =>
                  ProfessorBookingModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception('Error al obtener profesores: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error in getProfessors: $e');
      rethrow;
    }
  }

  /// Get available schedules for a specific professor
  Future<List<AvailableScheduleModel>> getAvailableSchedules(
    String professorId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      debugPrint('Getting available schedules for professor: $professorId');

      final response = await http.get(
        Uri.parse(
          '$_baseUrl/student-dashboard/available-schedules?professorId=$professorId',
        ),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) =>
                  AvailableScheduleModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Error al obtener horarios disponibles: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Error in getAvailableSchedules: $e');
      rethrow;
    }
  }

  /// Book a lesson
  Future<Map<String, dynamic>> bookLesson(String scheduleId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      debugPrint('Booking lesson with scheduleId: $scheduleId');

      final response = await http.post(
        Uri.parse('$_baseUrl/student-dashboard/book-lesson'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode({'scheduleId': scheduleId}),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al reservar clase');
      }
    } catch (e) {
      debugPrint('Error in bookLesson: $e');
      rethrow;
    }
  }
}

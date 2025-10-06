import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/recent_activity_model.dart';
import '../models/booking_model.dart';

/// Service responsible for student-related operations
/// Handles student dashboard data and activity tracking
/// Manages API communication for student-specific endpoints
class StudentService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Retrieves recent activities for the authenticated student
  /// Returns a list of [RecentActivityModel] objects
  /// Throws [Exception] if authentication fails or API request fails
  Future<List<RecentActivityModel>> getRecentActivities() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/student-dashboard/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) =>
                  RecentActivityModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Error al obtener actividades recientes: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get student profile information
  Future<Map<String, dynamic>> getStudentInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/student-dashboard/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception(
          'Error al obtener información del estudiante: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get student bookings
  Future<List<BookingModel>> getBookings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/student-dashboard/bookings'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) => BookingModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else {
        throw Exception(
          'Error al obtener reservas: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

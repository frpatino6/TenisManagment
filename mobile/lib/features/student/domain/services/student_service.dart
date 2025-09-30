import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/recent_activity_model.dart';

class StudentService {
  final String _baseUrl = 'http://192.168.18.6:3000/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get recent activities for the current student
  Future<List<RecentActivityModel>> getRecentActivities() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      // Force refresh token to ensure it's valid
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      debugPrint('Getting recent activities for student');
      debugPrint('Token length: ${idToken.length}');

      final response = await http.get(
        Uri.parse('$_baseUrl/student-dashboard/activities'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

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
      debugPrint('Error in getRecentActivities: $e');
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
      debugPrint('Error in getStudentInfo: $e');
      rethrow;
    }
  }
}

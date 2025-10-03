import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../models/student_model.dart';

/// Service responsible for managing student-related operations
/// Handles API communication for fetching student data and profiles
class StudentsService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Retrieves the complete list of students from the professor's endpoint
  /// Returns a list of [StudentModel] objects
  /// Throws [Exception] if the API request fails
  Future<List<StudentModel>> getStudentsList() async {
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
        final List<dynamic> items = data['items'] as List<dynamic>;

        return items.map((json) => StudentModel.fromJson(json)).toList();
      } else {
        throw Exception('Error al cargar estudiantes: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves a specific student's profile by ID
  /// [studentId] - The unique identifier of the student
  /// Returns [StudentModel] if found, null otherwise
  /// Throws [Exception] if the operation fails
  Future<StudentModel?> getStudentProfile(String studentId) async {
    try {
      final students = await getStudentsList();
      return students.where((s) => s.id == studentId).firstOrNull;
    } catch (e) {
      throw Exception('Error al cargar perfil del estudiante: $e');
    }
  }
}

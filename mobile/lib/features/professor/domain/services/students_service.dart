import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
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
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

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
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar estudiantes',
          statusCode: response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(
        message: 'Error de conexión: ${e.toString()}',
      );
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
    } on AppException {
      rethrow;
    } catch (e) {
      throw DomainException.notFound(
        resource: 'Estudiante',
        id: studentId,
        originalError: e,
      );
    }
  }
}

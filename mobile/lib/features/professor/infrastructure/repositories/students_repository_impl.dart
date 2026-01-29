import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/constants/timeouts.dart';
import '../../domain/repositories/students_repository.dart';
import '../../domain/models/student_model.dart';

/// Infrastructure implementation of [StudentsRepository]
/// 
/// Handles all HTTP communication, authentication, and data parsing.
/// This is where all "dirty" infrastructure concerns live.
class StudentsRepositoryImpl implements StudentsRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<List<StudentModel>> getStudentsList() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final response = await http
          .get(
            Uri.parse('$_baseUrl/professor-dashboard/students'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> items = data['items'] as List<dynamic>;

        return items
            .map((json) => StudentModel.fromJson(json as Map<String, dynamic>))
            .toList();
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

  @override
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

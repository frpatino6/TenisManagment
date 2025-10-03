import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../models/student_model.dart';

class StudentsService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  Future<List<StudentModel>> getStudentsList() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/professor/students'),
        headers: {
          'Content-Type': 'application/json',
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

  Future<StudentModel?> getStudentProfile(String studentId) async {
    try {
      // Por ahora, obtenemos el perfil del estudiante desde la lista
      // En el futuro se puede implementar un endpoint específico
      final students = await getStudentsList();
      return students.where((s) => s.id == studentId).firstOrNull;
    } catch (e) {
      throw Exception('Error al cargar perfil del estudiante: $e');
    }
  }
}

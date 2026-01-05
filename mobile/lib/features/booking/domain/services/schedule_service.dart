import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/schedule_model.dart';

/// Service for managing schedule (booking) operations
class ScheduleService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final Ref _ref;

  ScheduleService(this._ref);

  /// Get professor schedules grouped by tenant (center)
  /// GET /api/student-dashboard/professors/:professorId/schedules
  Future<ProfessorSchedulesResponse> getProfessorSchedules(
    String professorId,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final client = AppHttpClient(_ref);
      final response = await client.get(
        Uri.parse(
          '$_baseUrl/student-dashboard/professors/$professorId/schedules',
        ),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return ProfessorSchedulesResponse.fromJson(data);
      } else if (response.statusCode == 404) {
        throw DomainException.notFound(resource: 'Profesor', id: professorId);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        final errorData = json.decode(response.body) as Map<String, dynamic>?;
        final errorMessage =
            errorData?['error'] as String? ?? 'Error al obtener horarios';
        throw NetworkException.serverError(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for ScheduleService
final scheduleServiceProvider = Provider<ScheduleService>((ref) {
  return ScheduleService(ref);
});

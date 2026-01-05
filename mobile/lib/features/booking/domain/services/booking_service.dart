import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/professor_model.dart';
import '../models/available_schedule_model.dart';

class BookingService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppHttpClient _http;

  BookingService(this._http);

  /// Get list of all professors
  Future<List<ProfessorBookingModel>> getProfessors() async {
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

      final response = await _http.get(
        Uri.parse('$_baseUrl/student-dashboard/professors'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) =>
                  ProfessorBookingModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener profesores',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
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
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _http.get(
        Uri.parse(
          '$_baseUrl/student-dashboard/available-schedules?professorId=$professorId',
        ),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

        return items
            .map(
              (item) =>
                  AvailableScheduleModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw DomainException.notFound(resource: 'Profesor', id: professorId);
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener horarios disponibles',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Book a lesson
  Future<Map<String, dynamic>> bookLesson(
    String scheduleId, {
    required String serviceType,
    required double price,
  }) async {
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

      final response = await _http.post(
        Uri.parse('$_baseUrl/student-dashboard/book-lesson'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'scheduleId': scheduleId,
          'serviceType': serviceType,
          'price': price,
        }),
      );

      if (response.statusCode == 201) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al reservar clase';

        if (response.statusCode == 400 || response.statusCode == 422) {
          throw ValidationException(errorMessage, code: 'VALIDATION_ERROR');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 404) {
          throw ScheduleException.notFound();
        } else if (response.statusCode == 409) {
          throw ScheduleException.conflict(message: errorMessage);
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }
}

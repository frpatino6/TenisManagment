import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/professor_model.dart';
import '../models/available_schedule_model.dart';

/// Service for managing booking operations for students
/// Handles professor selection, schedule availability, and lesson booking
class BookingService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final AppHttpClient _http;

  BookingService(
    this._http, {
    FirebaseAuth? firebaseAuth,
  }) : _auth = firebaseAuth ?? FirebaseAuth.instance;

  /// Retrieves the list of all available professors
  ///
  /// Returns a list of [ProfessorBookingModel] containing professor information
  /// such as name, email, specialties, and pricing.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no professors are available
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
            .cast<Map<String, dynamic>>()
            .map((item) => ProfessorBookingModel.fromJson(item))
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

  /// Retrieves available schedules for a specific professor
  ///
  /// [professorId] The ID of the professor to get schedules for
  ///
  /// Returns a list of [AvailableScheduleModel] representing available
  /// time slots that can be booked.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [DomainException.notFound] if the professor does not exist
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no schedules are available
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
            .cast<Map<String, dynamic>>()
            .map((item) => AvailableScheduleModel.fromJson(item))
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

  /// Books a lesson with a professor
  ///
  /// [scheduleId] The ID of the schedule slot to book
  /// [serviceType] Type of service (e.g., 'individual_class', 'group_class')
  /// [price] The price for the lesson
  ///
  /// Returns a [Map] containing the booking confirmation data including booking ID
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [ValidationException] if the booking data is invalid
  /// Throws [ScheduleException.notFound] if the schedule does not exist
  /// Throws [ScheduleException.conflict] if the schedule is already booked
  /// Throws [NetworkException] if the API request fails
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

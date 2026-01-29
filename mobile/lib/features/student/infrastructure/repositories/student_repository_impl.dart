import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../domain/repositories/student_repository.dart';
import '../../domain/models/recent_activity_model.dart';
import '../../domain/models/booking_model.dart';
import '../../domain/models/student_payment_model.dart';

/// Infrastructure implementation of [StudentRepository]
/// 
/// Handles all HTTP communication, authentication, and data parsing.
/// This is where all "dirty" infrastructure concerns live.
class StudentRepositoryImpl implements StudentRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final AppHttpClient _httpClient;

  StudentRepositoryImpl({
    FirebaseAuth? firebaseAuth,
    required AppHttpClient httpClient,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _httpClient = httpClient;

  /// Get authorization headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException.notAuthenticated();
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null) {
      throw AuthException.notAuthenticated();
    }

    return {'Authorization': 'Bearer $idToken'};
  }

  @override
  Future<List<StudentPaymentModel>> getPaymentHistory({
    DateTime? from,
    DateTime? to,
    String? status,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final queryParams = <String, String>{};
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/student-dashboard/payments/history',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .cast<Map<String, dynamic>>()
            .map((item) => StudentPaymentModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener historial de pagos',
          statusCode: response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(message: 'Error inesperado: $e');
    }
  }

  @override
  Future<List<RecentActivityModel>> getRecentActivities() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/student-dashboard/activities'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .cast<Map<String, dynamic>>()
            .map((item) => RecentActivityModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener actividades recientes',
          statusCode: response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(message: 'Error inesperado: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> getStudentInfo() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/student-dashboard/me'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw DomainException.notFound(resource: 'Estudiante');
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener información del estudiante',
          statusCode: response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(message: 'Error inesperado: $e');
    }
  }

  @override
  Future<List<BookingModel>> getBookings() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await _httpClient.get(
        Uri.parse('$_baseUrl/student-dashboard/bookings'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .cast<Map<String, dynamic>>()
            .map((item) => BookingModel.fromJson(item))
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener reservas',
          statusCode: response.statusCode,
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(message: 'Error inesperado: $e');
    }
  }
}

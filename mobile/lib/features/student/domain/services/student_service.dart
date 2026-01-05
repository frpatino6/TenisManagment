import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/constants/timeouts.dart';
import '../models/recent_activity_model.dart';
import '../models/booking_model.dart';

/// Service responsible for student-related operations
/// Handles student dashboard data and activity tracking
/// Manages API communication for student-specific endpoints
class StudentService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final http.Client _httpClient;

  StudentService({
    FirebaseAuth? firebaseAuth,
    http.Client? httpClient,
  })  : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _httpClient = httpClient ?? http.Client();

  /// Retrieves recent activities for the authenticated student
  ///
  /// Returns a list of [RecentActivityModel] objects representing
  /// recent bookings, classes, and other activities.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no activities exist
  Future<List<RecentActivityModel>> getRecentActivities() async {
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

      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/student-dashboard/activities'),
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
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

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
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves the student's profile information
  ///
  /// Returns a [Map] containing student data such as:
  /// - Name, email, phone
  /// - Membership type
  /// - Balance
  /// - Statistics
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [DomainException.notFound] if the student profile does not exist
  /// Throws [NetworkException] if the API request fails
  Future<Map<String, dynamic>> getStudentInfo() async {
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

      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/student-dashboard/me'),
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
    } catch (e) {
      rethrow;
    }
  }

  /// Retrieves all bookings for the authenticated student
  ///
  /// Returns a list of [BookingModel] representing all bookings
  /// including upcoming, past, and cancelled bookings.
  ///
  /// Throws [AuthException.notAuthenticated] if user is not authenticated
  /// Throws [AuthException.tokenExpired] if authentication token is invalid
  /// Throws [NetworkException] if the API request fails
  ///
  /// Returns an empty list if no bookings exist
  Future<List<BookingModel>> getBookings() async {
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

      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/student-dashboard/bookings'),
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
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>;

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
    } catch (e) {
      rethrow;
    }
  }
}

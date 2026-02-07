import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../domain/repositories/court_repository.dart';
import '../../domain/models/court_model.dart';

/// Infrastructure implementation of [CourtRepository]
///
/// Handles all HTTP communication, authentication, and data parsing.
/// This is where all "dirty" infrastructure concerns live.
class CourtRepositoryImpl implements CourtRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppHttpClient _http;

  CourtRepositoryImpl(this._http);

  @override
  Future<List<CourtModel>> getCourts() async {
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
        Uri.parse('$_baseUrl/student-dashboard/courts'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .map((item) => CourtModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw ValidationException(
          error['error'] as String? ?? 'Error al obtener canchas',
          code: 'VALIDATION_ERROR',
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener canchas',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> getAvailableSlots({
    required String courtId,
    required DateTime date,
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

      final dateStr = date.toIso8601String().split('T')[0];

      final response = await _http.get(
        Uri.parse(
          '$_baseUrl/student-dashboard/courts/$courtId/available-slots?date=$dateStr',
        ),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        try {
          final error = json.decode(response.body) as Map<String, dynamic>;
          final errorMessage =
              error['error'] as String? ??
              'Error al obtener horarios disponibles';

          if (response.statusCode == 400 || response.statusCode == 422) {
            throw ValidationException(errorMessage, code: 'VALIDATION_ERROR');
          } else if (response.statusCode == 401 || response.statusCode == 403) {
            throw AuthException.tokenExpired();
          } else {
            throw NetworkException.serverError(
              message: errorMessage,
              statusCode: response.statusCode,
            );
          }
        } on AppException {
          rethrow;
        } catch (e) {
          throw NetworkException.serverError(
            message: 'Error al obtener horarios disponibles',
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Map<String, dynamic>> bookCourt({
    required String courtId,
    required DateTime startTime,
    required DateTime endTime,
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
        Uri.parse('$_baseUrl/student-dashboard/book-court'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'courtId': courtId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'price': price,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al reservar cancha';

        if (response.statusCode == 400 || response.statusCode == 422) {
          throw ValidationException(errorMessage, code: 'VALIDATION_ERROR');
        } else if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 409) {
          throw DomainException.conflict(message: errorMessage);
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

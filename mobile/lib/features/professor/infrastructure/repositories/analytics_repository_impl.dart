import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../domain/models/analytics_overview.dart';
import '../../domain/models/analytics_chart_data.dart';
import '../../domain/models/analytics_error.dart';

/// Infrastructure implementation of [AnalyticsRepository]
///
/// Handles all HTTP communication, authentication, and data parsing.
/// This is where all "dirty" infrastructure concerns live.
class AnalyticsRepositoryImpl implements AnalyticsRepository {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  @override
  Future<AnalyticsOverview> getOverview({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    const endpoint = 'professor-dashboard/analytics/overview';

    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AnalyticsError.authenticationError(endpoint: endpoint);
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/$endpoint',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(Timeouts.httpRequestLong);

      if (response.statusCode == 200) {
        try {
          final Map<String, dynamic> data = json.decode(response.body);
          return AnalyticsOverview.fromJson(data);
        } catch (e) {
          throw AnalyticsError(
            type: AnalyticsErrorType.dataValidationError,
            message: 'Error al procesar los datos recibidos.',
            details: 'Formato de respuesta inválido: $e',
            endpoint: endpoint,
            timestamp: DateTime.now(),
          );
        }
      } else {
        throw AnalyticsError.fromHttpResponse(
          statusCode: response.statusCode,
          endpoint: endpoint,
          responseBody: response.body,
        );
      }
    } on http.ClientException catch (e) {
      throw AnalyticsError.networkError(
        endpoint: endpoint,
        details: 'Error de red: ${e.message}',
      );
    } on FormatException catch (e) {
      throw AnalyticsError(
        type: AnalyticsErrorType.dataValidationError,
        message: 'Error al procesar la respuesta del servidor.',
        details: 'Formato inválido: ${e.message}',
        endpoint: endpoint,
        timestamp: DateTime.now(),
      );
    } on AnalyticsError {
      rethrow;
    } catch (e) {
      throw AnalyticsError(
        type: AnalyticsErrorType.unknownError,
        message: 'Error inesperado al cargar analytics.',
        details: e.toString(),
        endpoint: endpoint,
        timestamp: DateTime.now(),
      );
    }
  }

  @override
  Future<AnalyticsChartData> getRevenueData({String period = 'month'}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/revenue',
      ).replace(queryParameters: {'period': period});

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsChartData.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar datos de ingresos',
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
  Future<AnalyticsChartData> getBookingsData({String period = 'month'}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/bookings',
      ).replace(queryParameters: {'period': period});

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsChartData.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar datos de clases',
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
  Future<AnalyticsChartData> getStudentsData({String period = 'month'}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/students',
      ).replace(queryParameters: {'period': period});

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsChartData.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar datos de estudiantes',
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
  Future<Map<String, dynamic>> getRevenueBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/revenue/breakdown',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar desglose de ingresos',
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
  Future<Map<String, dynamic>> getBookingsBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/bookings/breakdown',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar desglose de clases',
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
  Future<Map<String, dynamic>> getRevenueTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/revenue/trend',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar tendencia de ingresos',
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
  Future<Map<String, dynamic>> getBookingsTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/bookings/trend',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar tendencia de clases',
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
  Future<Map<String, dynamic>> getStudentsBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/students/breakdown',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar desglose de estudiantes',
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
  Future<Map<String, dynamic>> getStudentsTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/students/trend',
      ).replace(queryParameters: queryParams);

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else {
        throw NetworkException.serverError(
          message: 'Error al cargar tendencia de estudiantes',
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
  Future<Map<String, dynamic>> getOccupancyDetails({
    String period = 'month',
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/occupancy/details',
      ).replace(queryParameters: {'period': period});

      final response = await http
          .get(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequestLong,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar datos de ocupación: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }
}

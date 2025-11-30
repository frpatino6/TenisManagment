import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../models/analytics_overview.dart';
import '../models/analytics_chart_data.dart';
import '../models/analytics_error.dart';

/// Service responsible for managing analytics-related operations
/// Handles API communication for fetching analytics data and charts
class AnalyticsService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Retrieves the complete analytics overview from the professor's endpoint
  /// Returns [AnalyticsOverview] with metrics and charts
  /// Throws [AnalyticsError] if the API request fails
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
          .timeout(const Duration(seconds: 30));

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

  /// Retrieves revenue analytics data
  /// Returns [AnalyticsChartData] with revenue information
  Future<AnalyticsChartData> getRevenueData({String period = 'month'}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/revenue',
      ).replace(queryParameters: {'period': period});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsChartData.fromJson(data);
      } else {
        throw Exception(
          'Error al cargar datos de ingresos: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves bookings analytics data
  /// Returns [AnalyticsChartData] with booking information
  Future<AnalyticsChartData> getBookingsData({String period = 'month'}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/bookings',
      ).replace(queryParameters: {'period': period});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsChartData.fromJson(data);
      } else {
        throw Exception(
          'Error al cargar datos de clases: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves students analytics data
  /// Returns [AnalyticsChartData] with student information
  Future<AnalyticsChartData> getStudentsData({String period = 'month'}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/students',
      ).replace(queryParameters: {'period': period});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsChartData.fromJson(data);
      } else {
        throw Exception(
          'Error al cargar datos de estudiantes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves revenue breakdown data
  /// Returns breakdown data with real values from database
  Future<Map<String, dynamic>> getRevenueBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/revenue/breakdown',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar desglose de ingresos: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves bookings breakdown data
  /// Returns breakdown data with real values from database
  Future<Map<String, dynamic>> getBookingsBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/bookings/breakdown',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar desglose de clases: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves revenue trend data
  /// Returns trend data with real values from database
  Future<Map<String, dynamic>> getRevenueTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/revenue/trend',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar tendencia de ingresos: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves bookings trend data
  /// Returns trend data with real values from database
  Future<Map<String, dynamic>> getBookingsTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/bookings/trend',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar tendencia de clases: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves students breakdown data
  /// Returns breakdown data with real values from database
  Future<Map<String, dynamic>> getStudentsBreakdown({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/students/breakdown',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar desglose de estudiantes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves students trend data
  /// Returns trend data with real values from database
  Future<Map<String, dynamic>> getStudentsTrend({
    String period = 'month',
    String? serviceType,
    String? status,
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/students/trend',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception(
          'Error al cargar tendencia de estudiantes: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
    }
  }

  /// Retrieves occupancy details data
  /// Returns real occupancy data from database with time slots and trends
  Future<Map<String, dynamic>> getOccupancyDetails({
    String period = 'month',
  }) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/occupancy/details',
      ).replace(queryParameters: {'period': period});

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
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

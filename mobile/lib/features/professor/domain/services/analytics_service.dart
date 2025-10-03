import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../models/analytics_overview.dart';
import '../models/analytics_chart_data.dart';

/// Service responsible for managing analytics-related operations
/// Handles API communication for fetching analytics data and charts
class AnalyticsService {
  String get _baseUrl => AppConfig.apiBaseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  /// Retrieves the complete analytics overview from the professor's endpoint
  /// Returns [AnalyticsOverview] with metrics and charts
  /// Throws [Exception] if the API request fails
  Future<AnalyticsOverview> getOverview({
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

      // Build query parameters
      final queryParams = <String, String>{'period': period};
      if (serviceType != null) queryParams['serviceType'] = serviceType;
      if (status != null) queryParams['status'] = status;

      final uri = Uri.parse(
        '$_baseUrl/professor-dashboard/analytics/overview',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return AnalyticsOverview.fromJson(data);
      } else {
        throw Exception('Error al cargar analytics: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error de conexión: $e');
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
}

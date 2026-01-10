import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/constants/timeouts.dart';
import '../models/tenant_metrics_model.dart';
import '../models/tenant_config_model.dart';
import '../models/tenant_professor_model.dart';
import '../models/tenant_court_model.dart';
import '../models/tenant_booking_model.dart';
import '../models/booking_stats_model.dart';
import '../models/tenant_student_model.dart';

/// Service responsible for tenant admin operations
/// Handles API communication for tenant admin endpoints
class TenantAdminService {
  final FirebaseAuth _auth;
  final String _baseUrl = AppConfig.apiBaseUrl;
  final AppHttpClient _httpClient;

  TenantAdminService({required AppHttpClient httpClient, FirebaseAuth? auth})
    : _httpClient = httpClient,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get authorization headers
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw AuthException.notAuthenticated();
    }

    final idToken = await user.getIdToken(true);
    if (idToken == null) {
      throw AuthException.tokenExpired();
    }

    return {'Authorization': 'Bearer $idToken'};
  }

  /// GET /api/tenant/metrics
  /// Get metrics for the tenant
  Future<TenantMetricsModel> getMetrics() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/metrics');

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantMetricsModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/me
  /// Get tenant information
  Future<TenantConfigModel> getTenantInfo() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/me');

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantConfigModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PUT /api/tenant/me
  /// Update tenant configuration
  Future<TenantConfigModel> updateTenantConfig({
    String? name,
    String? slug,
    String? domain,
    TenantConfigData? config,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/me');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (slug != null) body['slug'] = slug;
      if (domain != null) body['domain'] = domain;
      if (config != null) body['config'] = config.toJson();

      final response = await _httpClient.put(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantConfigModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode == 409) {
        throw ValidationException(
          'El slug o dominio ya está en uso',
          code: 'DUPLICATE_SLUG_OR_DOMAIN',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PUT /api/tenant/operating-hours
  /// Update operating hours
  Future<TenantConfigModel> updateOperatingHours({
    required List<Map<String, dynamic>>
    schedule, // Array of {dayOfWeek, open, close}
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/operating-hours');

      final body = <String, dynamic>{'schedule': schedule};

      final bodyJson = json.encode(body);

      final response = await _httpClient.put(
        uri,
        headers: headers,
        body: bodyJson,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        // Operating hours update returns the full tenant config
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantConfigModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Datos inválidos',
          code: 'INVALID_OPERATING_HOURS',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/professors
  /// Get list of professors for the tenant
  Future<List<TenantProfessorModel>> getProfessors() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/professors');

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final professorsList = data['professors'] as List<dynamic>? ?? [];
        return professorsList
            .map(
              (item) =>
                  TenantProfessorModel.fromJson(item as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// POST /api/tenant/professors/invite
  /// Invite a professor to the tenant
  Future<void> inviteProfessor({
    required String email,
    Map<String, dynamic>? pricing,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/professors/invite');

      final body = <String, dynamic>{'email': email};
      if (pricing != null) {
        body['pricing'] = pricing;
      }

      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 201) {
        return; // Success
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Profesor no encontrado',
          code: 'PROFESSOR_NOT_FOUND',
        );
      } else if (response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'El profesor ya está activo',
          code: 'PROFESSOR_ALREADY_ACTIVE',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        final errorData = json.decode(response.body);
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: errorData['error']?.toString() ?? 'Error inesperado',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PATCH /api/tenant/professors/:id/activate
  /// Activate a professor in the tenant
  Future<void> activateProfessor(String professorId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse(
        '$_baseUrl/tenant/professors/$professorId/activate',
      );

      final response = await _httpClient.patch(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Profesor no encontrado',
          code: 'PROFESSOR_NOT_FOUND',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PATCH /api/tenant/professors/:id/deactivate
  /// Deactivate a professor in the tenant
  Future<void> deactivateProfessor(String professorId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse(
        '$_baseUrl/tenant/professors/$professorId/deactivate',
      );

      final response = await _httpClient.patch(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Profesor no encontrado',
          code: 'PROFESSOR_NOT_FOUND',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PUT /api/tenant/professors/:id
  /// Update professor details
  Future<TenantProfessorModel> updateProfessor({
    required String professorId,
    String? name,
    String? phone,
    double? hourlyRate,
    List<String>? specialties,
    Map<String, dynamic>? pricing,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/professors/$professorId');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (phone != null) body['phone'] = phone;
      if (hourlyRate != null) body['hourlyRate'] = hourlyRate;
      if (specialties != null) body['specialties'] = specialties;
      if (pricing != null) body['pricing'] = pricing;

      final response = await _httpClient.put(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantProfessorModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Datos inválidos',
          code: 'INVALID_DATA',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/courts
  /// Get list of courts for the tenant
  Future<List<TenantCourtModel>> getCourts() async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/courts');

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final List<dynamic> courtsJson = data['courts'] as List<dynamic>;
        return courtsJson
            .map(
              (json) => TenantCourtModel.fromJson(json as Map<String, dynamic>),
            )
            .toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// POST /api/tenant/courts
  /// Create a new court
  Future<TenantCourtModel> createCourt({
    required String name,
    required String type,
    required double price,
    String? description,
    List<String>? features,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/courts');

      final body = <String, dynamic>{
        'name': name,
        'type': type,
        'price': price,
      };
      if (description != null) body['description'] = description;
      if (features != null) body['features'] = features;

      final response = await _httpClient.post(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantCourtModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode == 400 || response.statusCode == 409) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Error al crear cancha',
          code: 'CREATE_COURT_ERROR',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PUT /api/tenant/courts/:id
  /// Update a court
  Future<TenantCourtModel> updateCourt({
    required String courtId,
    String? name,
    String? type,
    double? price,
    String? description,
    List<String>? features,
    bool? isActive,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/courts/$courtId');

      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (type != null) body['type'] = type;
      if (price != null) body['price'] = price;
      if (description != null) body['description'] = description;
      if (features != null) body['features'] = features;
      if (isActive != null) body['isActive'] = isActive;

      final response = await _httpClient.put(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantCourtModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// DELETE /api/tenant/courts/:id
  /// Delete a court
  Future<void> deleteCourt(String courtId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/courts/$courtId');

      final response = await _httpClient.delete(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        return;
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/bookings
  /// Get list of bookings with filters
  Future<Map<String, dynamic>> getBookings({
    String? status,
    DateTime? from,
    DateTime? to,
    String? courtId,
    String? professorId,
    String? studentId,
    String? search,
    String? serviceType,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (status != null) queryParams['status'] = status;
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();
      if (courtId != null) queryParams['courtId'] = courtId;
      if (professorId != null) queryParams['professorId'] = professorId;
      if (studentId != null) queryParams['studentId'] = studentId;
      if (search != null) queryParams['search'] = search;
      if (serviceType != null) queryParams['serviceType'] = serviceType;

      final uri = Uri.parse(
        '$_baseUrl/tenant/bookings',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final bookingsList = data['bookings'] as List<dynamic>? ?? [];
        final paginationData = data['pagination'] as Map<String, dynamic>;

        return {
          'bookings': bookingsList
              .map(
                (item) =>
                    TenantBookingModel.fromJson(item as Map<String, dynamic>),
              )
              .toList(),
          'pagination': BookingPagination.fromJson(paginationData),
        };
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/bookings/calendar
  /// Get calendar view of bookings
  Future<Map<String, List<Map<String, dynamic>>>> getBookingCalendar({
    required DateTime from,
    required DateTime to,
    String? courtId,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final queryParams = <String, String>{
        'from': from.toIso8601String(),
        'to': to.toIso8601String(),
      };

      if (courtId != null) queryParams['courtId'] = courtId;

      final uri = Uri.parse(
        '$_baseUrl/tenant/bookings/calendar',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final calendar = data['calendar'] as Map<String, dynamic>;

        return calendar.map(
          (key, value) => MapEntry(
            key,
            (value as List<dynamic>)
                .map((item) => item as Map<String, dynamic>)
                .toList(),
          ),
        );
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 400) {
        throw ValidationException(
          'Parámetros inválidos',
          code: 'INVALID_PARAMS',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/bookings/:id
  /// Get booking details
  Future<TenantBookingModel> getBookingDetails(String bookingId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/bookings/$bookingId');

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantBookingModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw ValidationException(
          'Reserva no encontrada',
          code: 'BOOKING_NOT_FOUND',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PATCH /api/tenant/bookings/:id/cancel
  /// Cancel a booking
  Future<void> cancelBooking(String bookingId, {String? reason}) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/bookings/$bookingId/cancel');

      final body = <String, dynamic>{};
      if (reason != null) body['reason'] = reason;

      final response = await _httpClient.patch(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        return; // Success
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw ValidationException(
          'Reserva no encontrada',
          code: 'BOOKING_NOT_FOUND',
        );
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'No se puede cancelar la reserva',
          code: 'CANNOT_CANCEL',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/bookings/stats
  /// Get booking statistics
  Future<BookingStatsModel> getBookingStats({
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final queryParams = <String, String>{};
      if (from != null) queryParams['from'] = from.toIso8601String();
      if (to != null) queryParams['to'] = to.toIso8601String();

      final uri = Uri.parse(
        '$_baseUrl/tenant/bookings/stats',
      ).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return BookingStatsModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/students
  /// Get list of students with filters and pagination
  Future<TenantStudentsResponse> getStudents({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (search != null && search.isNotEmpty) queryParams['search'] = search;

      final uri = Uri.parse(
        '$_baseUrl/tenant/students',
      ).replace(queryParameters: queryParams);

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantStudentsResponse.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// GET /api/tenant/students/:id
  /// Get detailed information of a student
  Future<TenantStudentDetailsModel> getStudentDetails(String studentId) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/students/$studentId');

      final response = await _httpClient.get(
        uri,
        headers: headers,
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return TenantStudentDetailsModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw ValidationException(
          'Estudiante no encontrado en este centro',
          code: 'STUDENT_NOT_FOUND',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }

  /// PATCH /api/tenant/students/:id/balance
  /// Update student balance
  Future<double> updateStudentBalance(
    String studentId, {
    required double amount,
    required String type, // 'add' | 'subtract' | 'set'
    String? reason,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/students/$studentId/balance');

      final body = <String, dynamic>{'amount': amount, 'type': type};
      if (reason != null) body['reason'] = reason;

      final response = await _httpClient.patch(
        uri,
        headers: headers,
        body: json.encode(body),
        timeout: Timeouts.httpRequest,
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return (data['newBalance'] as num).toDouble();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw ValidationException(
          'Estudiante no encontrado',
          code: 'STUDENT_NOT_FOUND',
        );
      } else if (response.statusCode == 400) {
        final errorData = json.decode(response.body);
        throw ValidationException(
          errorData['error']?.toString() ?? 'Error al actualizar balance',
          code: 'BALANCE_UPDATE_ERROR',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      } else {
        throw NetworkException.serverError(
          statusCode: response.statusCode,
          message: 'Error inesperado: ${response.statusCode}',
        );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      if (e is AppException) {
        rethrow;
      }
      throw NetworkException.serverError(
        statusCode: 0,
        message: 'Error desconocido: ${e.toString()}',
      );
    }
  }
}

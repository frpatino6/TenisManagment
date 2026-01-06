import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/constants/timeouts.dart';
import '../models/tenant_metrics_model.dart';
import '../models/tenant_config_model.dart';
import '../models/tenant_professor_model.dart';

/// Service responsible for tenant admin operations
/// Handles API communication for tenant admin endpoints
class TenantAdminService {
  final FirebaseAuth _auth;
  final Ref _ref;
  final String _baseUrl = AppConfig.apiBaseUrl;

  TenantAdminService({required Ref ref, FirebaseAuth? auth})
    : _ref = ref,
      _auth = auth ?? FirebaseAuth.instance;

  /// Get HTTP client with automatic X-Tenant-ID header
  AppHttpClient get _httpClient => AppHttpClient(_ref);

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
    required String open,
    required String close,
    List<int>? daysOfWeek,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final uri = Uri.parse('$_baseUrl/tenant/operating-hours');

      final body = <String, dynamic>{'open': open, 'close': close};
      if (daysOfWeek != null) {
        body['daysOfWeek'] = daysOfWeek;
      }

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
}

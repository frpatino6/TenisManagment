import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../constants/timeouts.dart';
import '../exceptions/exceptions.dart';

/// Service responsible for managing tenant (center) configuration
/// Now uses MongoDB backend instead of SharedPreferences
/// Stateless service - all state is managed by Riverpod providers
class TenantService {
  final FirebaseAuth _auth;
  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Constructor with optional FirebaseAuth for testing
  TenantService({FirebaseAuth? auth}) : _auth = auth ?? FirebaseAuth.instance;

  /// Load the tenant ID from backend
  /// Returns the first favorite tenant ID (no longer uses activeTenantId)
  /// Returns null if no favorite tenant is configured
  /// Stateless - always loads fresh from backend
  /// Tries tenant_admin endpoint first, then professor endpoint, then student endpoint
  Future<String?> loadTenant() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      final idTokenResult = await user.getIdTokenResult(true);
      final token = idTokenResult.token;
      if (token == null) {
        return null;
      }

      final claims = idTokenResult.claims;
      final role = claims?['role'] as String?;

      // Route based on role to avoid 403 errors
      if (role == 'tenant_admin') {
        // Try tenant_admin endpoint (GET /api/tenant/me)
        final response = await http
            .get(
              Uri.parse('$_baseUrl/tenant/me'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
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
          final tenantId = data['id'] as String?;
          return tenantId;
        }
        return null;
      } else if (role == 'professor') {
        // Try professor endpoint
        final response = await http
            .get(
              Uri.parse('$_baseUrl/professor-dashboard/active-tenant'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
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
          final tenantId = data['tenantId'] as String?;
          return tenantId;
        }
        return null;
      } else {
        // Default to student endpoint for 'student' role or others
        final response = await http
            .get(
              Uri.parse('$_baseUrl/student-dashboard/active-tenant'),
              headers: {
                'Authorization': 'Bearer $token',
                'Content-Type': 'application/json',
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
          final tenantId = data['tenantId'] as String?;
          return tenantId;
        }

        // Handle specific student errors or not found
        if (response.statusCode == 404) {
          return null; // No favorite tenant configured
        }

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        }

        if (response.statusCode >= 500) {
          throw NetworkException.serverError(statusCode: response.statusCode);
        }

        return null;
      }
    } on AppException {
      // Re-lanzar excepciones de la aplicación
      rethrow;
    } catch (e) {
      // Para otros errores (timeout, network, etc.), retornar null
      // El provider manejará el error apropiadamente
      return null;
    }
  }

  /// Set the tenant (adds to favorites and makes it first)
  /// No longer uses activeTenantId, uses favorites instead
  /// Returns true if successful, false otherwise
  /// Tries professor endpoint first, then student endpoint
  Future<bool> setTenant(String tenantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        return false;
      }

      // Try professor endpoint first
      var response = await http
          .post(
            Uri.parse('$_baseUrl/professor-dashboard/active-tenant'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
            body: json.encode({'tenantId': tenantId}),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout();
            },
          );

      if (response.statusCode == 200) {
        return true;
      }

      // If professor endpoint returns 404 or 403, try student endpoint
      if (response.statusCode == 404 || response.statusCode == 403) {
        response = await http
            .post(
              Uri.parse('$_baseUrl/student-dashboard/active-tenant'),
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
              },
              body: json.encode({'tenantId': tenantId}),
            )
            .timeout(
              Timeouts.httpRequest,
              onTimeout: () {
                throw NetworkException.timeout();
              },
            );

        if (response.statusCode == 200) {
          return true;
        }
      }

      // Manejar errores específicos
      if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw TenantException.notFound(tenantId: tenantId);
      } else if (response.statusCode == 400 || response.statusCode == 422) {
        throw ValidationException(
          'El ID del centro no es válido',
          code: 'INVALID_TENANT_ID',
        );
      } else if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }

      return false;
    } on AppException {
      // Re-lanzar excepciones de la aplicación
      rethrow;
    } catch (e) {
      // Para otros errores, retornar false
      return false;
    }
  }

  /// Clear the active tenant ID
  /// Note: This is not implemented in backend, but we can set it to null
  /// For now, we'll just return false as clearing is not needed
  Future<bool> clearTenant() async {
    // Backend doesn't have a clear endpoint, but we can handle this
    // by not setting a tenant. For logout, the state will be cleared in provider.
    return true;
  }
}

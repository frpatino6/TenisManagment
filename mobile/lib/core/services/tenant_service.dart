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

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        return null;
      }

      // Try tenant_admin endpoint first (GET /api/tenant/me)
      var response = await http
          .get(
            Uri.parse('$_baseUrl/tenant/me'),
            headers: {
              'Authorization': 'Bearer $idToken',
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

      // If tenant_admin endpoint returns 404, 403, or 401, try professor endpoint
      // (401 means user is not tenant_admin, so try other roles)
      if (response.statusCode == 404 ||
          response.statusCode == 403 ||
          response.statusCode == 401) {
        response = await http
            .get(
              Uri.parse('$_baseUrl/professor-dashboard/active-tenant'),
              headers: {
                'Authorization': 'Bearer $idToken',
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

        // If professor endpoint returns 404 or 403, try student endpoint
        if (response.statusCode == 404 || response.statusCode == 403) {
          final studentResponse = await http
              .get(
                Uri.parse('$_baseUrl/student-dashboard/active-tenant'),
                headers: {
                  'Authorization': 'Bearer $idToken',
                  'Content-Type': 'application/json',
                },
              )
              .timeout(
                Timeouts.httpRequest,
                onTimeout: () {
                  throw NetworkException.timeout();
                },
              );
          if (studentResponse.statusCode == 200) {
            final data =
                json.decode(studentResponse.body) as Map<String, dynamic>;
            final tenantId = data['tenantId'] as String?;
            return tenantId;
          }

          // If student endpoint returns 404, that's OK - no favorite tenant configured
          if (studentResponse.statusCode == 404) {
            return null;
          }

          // If student endpoint returns 401 or 403, that's an auth error
          if (studentResponse.statusCode == 401 ||
              studentResponse.statusCode == 403) {
            throw AuthException.tokenExpired();
          }

          // If student endpoint returns 500+, that's a server error
          if (studentResponse.statusCode >= 500) {
            throw NetworkException.serverError(
              statusCode: studentResponse.statusCode,
            );
          }
          return null;
        }

        // If professor endpoint returns 401 (not 404/403), that's an auth error
        if (response.statusCode == 401) {
          throw AuthException.tokenExpired();
        }

        // If professor endpoint returns 500+, that's a server error
        if (response.statusCode >= 500) {
          throw NetworkException.serverError(statusCode: response.statusCode);
        }

        return null;
      }

      // If tenant_admin endpoint returns 500+, that's a server error
      if (response.statusCode >= 500) {
        throw NetworkException.serverError(statusCode: response.statusCode);
      }

      // For any other status code from tenant_admin endpoint (not 404/403/401), return null
      return null;
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

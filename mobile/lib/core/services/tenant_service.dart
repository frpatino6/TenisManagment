import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

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
  /// Tries professor endpoint first, then student endpoint
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

      // Try professor endpoint first
      var response = await http
          .get(
            Uri.parse('$_baseUrl/professor-dashboard/active-tenant'),
            headers: {
              'Authorization': 'Bearer $idToken',
              'Content-Type': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final tenantId = data['tenantId'] as String?;
        return tenantId;
      }

      // If professor endpoint returns 404, try student endpoint
      if (response.statusCode == 404) {
        response = await http
            .get(
              Uri.parse('$_baseUrl/student-dashboard/active-tenant'),
              headers: {
                'Authorization': 'Bearer $idToken',
                'Content-Type': 'application/json',
              },
            )
            .timeout(const Duration(seconds: 10));

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final tenantId = data['tenantId'] as String?;
          return tenantId;
        }
      }

      return null;
    } catch (e) {
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
          .timeout(const Duration(seconds: 10));

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
            .timeout(const Duration(seconds: 10));

        return response.statusCode == 200;
      }

      return false;
    } catch (e) {
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

import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

/// Service responsible for managing tenant (center) configuration
/// Now uses MongoDB backend instead of SharedPreferences
/// Stateless service - all state is managed by Riverpod providers
class TenantService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _baseUrl = AppConfig.apiBaseUrl;

  /// Load the saved tenant ID from backend
  /// Returns the tenant ID if found, null otherwise
  /// Stateless - always loads fresh from backend
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

      final response = await http
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
      } else if (response.statusCode == 404) {
        // Student not found or no tenant set
        return null;
      } else {
        // Error response, return null
        return null;
      }
    } catch (e) {
      // On error, return null (no tenant configured)
      return null;
    }
  }

  /// Set the active tenant ID
  /// Saves to backend
  /// Returns true if successful, false otherwise
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

      final response = await http
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

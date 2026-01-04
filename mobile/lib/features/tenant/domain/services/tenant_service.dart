import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../models/tenant_model.dart';

/// Service for managing tenant (center) operations
class TenantService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppHttpClient _http;

  TenantService(this._http);

  /// Get all available active tenants for selection
  /// Returns all active tenants that can be selected
  /// Uses public endpoint if user is not authenticated (for registration)
  Future<List<TenantModel>> getAvailableTenants() async {
    try {
      final user = _auth.currentUser;

      // Si el usuario no está autenticado, usar endpoint público (para registro)
      if (user == null) {
        final response = await _http.get(
          Uri.parse('$_baseUrl/config/tenants/public'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];

          return items
              .map((item) => TenantModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else {
          throw Exception(
            'Error al obtener centros disponibles: ${response.statusCode}',
          );
        }
      }

      // Si el usuario está autenticado, usar endpoint con autenticación
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await _http.get(
        Uri.parse('$_baseUrl/student-dashboard/tenants/available'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        return items
            .map((item) => TenantModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        throw Exception(
          'Error al obtener centros disponibles: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get list of tenants for the current user
  /// For students: returns tenants where they have bookings
  /// For professors: returns tenants where they work
  Future<List<TenantModel>> getMyTenants() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      // Determine user role from token or user info
      // For now, we'll try both endpoints and see which one works
      // In a real scenario, we'd know the role from the user model

      // Try student endpoint first (most common)
      try {
        final response = await _http.get(
          Uri.parse('$_baseUrl/student-dashboard/tenants'),
          headers: {'Authorization': 'Bearer $idToken'},
        );

        if (response.statusCode == 200) {
          final data = json.decode(response.body) as Map<String, dynamic>;
          final items = data['items'] as List<dynamic>? ?? [];

          return items
              .map((item) => TenantModel.fromJson(item as Map<String, dynamic>))
              .toList();
        } else if (response.statusCode == 404) {
          // User might be a professor, try professor endpoint
          final profResponse = await _http.get(
            Uri.parse('$_baseUrl/professor-dashboard/tenants'),
            headers: {'Authorization': 'Bearer $idToken'},
          );

          if (profResponse.statusCode == 200) {
            final data = json.decode(profResponse.body) as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>? ?? [];

            return items
                .map(
                  (item) => TenantModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
        }

        throw Exception('Error al obtener centros: ${response.statusCode}');
      } catch (e) {
        // If student endpoint fails, try professor endpoint
        try {
          final profResponse = await _http.get(
            Uri.parse('$_baseUrl/professor-dashboard/tenants'),
            headers: {'Authorization': 'Bearer $idToken'},
          );

          if (profResponse.statusCode == 200) {
            final data = json.decode(profResponse.body) as Map<String, dynamic>;
            final items = data['items'] as List<dynamic>? ?? [];

            return items
                .map(
                  (item) => TenantModel.fromJson(item as Map<String, dynamic>),
                )
                .toList();
          }
        } catch (_) {
          // Ignore and throw original error
        }

        rethrow;
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Search for a tenant by code/slug
  /// Searches in all available tenants, not just user's tenants
  Future<TenantModel?> searchTenantByCode(String code) async {
    try {
      // Search in all available tenants, not just user's tenants
      final tenants = await getAvailableTenants();

      // Search by slug (most common)
      try {
        return tenants.firstWhere(
          (tenant) => tenant.slug.toLowerCase() == code.toLowerCase(),
        );
      } catch (e) {
        // If not found by slug, try by ID
        try {
          return tenants.firstWhere(
            (tenant) => tenant.id == code,
          );
        } catch (e) {
          return null;
        }
      }
    } catch (e) {
      return null;
    }
  }
}

/// Provider for TenantService (domain service)
final tenantDomainServiceProvider = Provider<TenantService>((ref) {
  return TenantService(ref.watch(appHttpClientProvider));
});

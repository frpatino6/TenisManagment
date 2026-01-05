import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../models/user_preferences_model.dart';

/// Service for managing user preferences (favorites)
class PreferencesService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppHttpClient _http;

  PreferencesService(this._http);

  /// Get user preferences
  /// GET /api/student-dashboard/preferences
  Future<UserPreferencesModel> getPreferences() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _http.get(
        Uri.parse('$_baseUrl/student-dashboard/preferences'),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return UserPreferencesModel.fromJson(data);
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al obtener preferencias';

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add professor to favorites
  /// POST /api/student-dashboard/preferences/favorite-professor
  Future<void> addFavoriteProfessor(String professorId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _http.post(
        Uri.parse('$_baseUrl/student-dashboard/preferences/favorite-professor'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'professorId': professorId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al agregar profesor favorito';

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 404) {
          throw DomainException.notFound(resource: 'Profesor');
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove professor from favorites
  /// DELETE /api/student-dashboard/preferences/favorite-professor/:professorId
  Future<void> removeFavoriteProfessor(String professorId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _http.delete(
        Uri.parse(
          '$_baseUrl/student-dashboard/preferences/favorite-professor/$professorId',
        ),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al eliminar profesor favorito';

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 404) {
          throw DomainException.notFound(resource: 'Profesor favorito');
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Add tenant to favorites
  /// POST /api/student-dashboard/preferences/favorite-tenant
  Future<void> addFavoriteTenant(String tenantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _http.post(
        Uri.parse('$_baseUrl/student-dashboard/preferences/favorite-tenant'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'tenantId': tenantId}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al agregar centro favorito';

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 404) {
          throw TenantException.notFound();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Remove tenant from favorites
  /// DELETE /api/student-dashboard/preferences/favorite-tenant/:tenantId
  Future<void> removeFavoriteTenant(String tenantId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _http.delete(
        Uri.parse(
          '$_baseUrl/student-dashboard/preferences/favorite-tenant/$tenantId',
        ),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage =
            error['error'] as String? ?? 'Error al eliminar centro favorito';

        if (response.statusCode == 401 || response.statusCode == 403) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 404) {
          throw TenantException.notFound();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Check if professor is favorite
  Future<bool> isProfessorFavorite(String professorId) async {
    try {
      final preferences = await getPreferences();
      return preferences.favoriteProfessors.any((p) => p.id == professorId);
    } catch (e) {
      return false;
    }
  }

  /// Check if tenant is favorite
  Future<bool> isTenantFavorite(String tenantId) async {
    try {
      final preferences = await getPreferences();
      return preferences.favoriteTenants.any((t) => t.id == tenantId);
    } catch (e) {
      return false;
    }
  }
}

/// Provider for PreferencesService
final preferencesServiceProvider = Provider<PreferencesService>((ref) {
  return PreferencesService(ref.watch(appHttpClientProvider));
});

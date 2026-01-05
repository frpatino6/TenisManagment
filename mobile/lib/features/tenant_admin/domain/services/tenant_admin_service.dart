import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../models/tenant_config_model.dart';
import '../models/tenant_metrics_model.dart';
import '../models/tenant_professor_model.dart';
import '../models/tenant_court_model.dart';

/// Service for Tenant Admin operations
/// Handles all tenant admin API endpoints
class TenantAdminService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final AppHttpClient _httpClient;

  TenantAdminService(this._httpClient);

  /// GET /api/tenant/me
  /// Obtener información del tenant
  Future<TenantConfigModel> getTenantInfo() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/me';
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TenantConfigModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('No autorizado');
      } else if (response.statusCode == 404) {
        throw Exception('Tenant no encontrado');
      } else {
        throw Exception(
          'Error al obtener información del tenant: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/tenant/me
  /// Actualizar configuración del tenant
  Future<TenantConfigModel> updateTenantInfo(
    Map<String, dynamic> updates,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/me';
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
        body: json.encode(updates),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TenantConfigModel.fromJson(data);
      } else {
        throw Exception(
          'Error al actualizar tenant: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/tenant/operating-hours
  /// Configurar horarios de operación
  Future<void> updateOperatingHours(OperatingHours operatingHours) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/operating-hours';
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
        body: json.encode(operatingHours.toJson()),
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al actualizar horarios: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/tenant/metrics
  /// Obtener métricas del centro
  Future<TenantMetricsModel> getMetrics() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/metrics';
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TenantMetricsModel.fromJson(data);
      } else {
        throw Exception(
          'Error al obtener métricas: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/tenant/professors
  /// Listar profesores del tenant
  Future<List<TenantProfessorModel>> getProfessors() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/professors';
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> professorsJson = data['professors'] ?? [];
        return professorsJson
            .map((json) => TenantProfessorModel.fromJson(
                  json as Map<String, dynamic>,
                ))
            .toList();
      } else {
        throw Exception(
          'Error al obtener profesores: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/tenant/professors/invite
  /// Invitar profesor al tenant
  Future<void> inviteProfessor(InviteProfessorRequest request) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/professors/invite';
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception(
          'Error al invitar profesor: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /api/tenant/professors/:id/activate
  /// Activar profesor
  Future<void> activateProfessor(String professorId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/professors/$professorId/activate';
      final response = await _httpClient.patch(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al activar profesor: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PATCH /api/tenant/professors/:id/deactivate
  /// Desactivar profesor
  Future<void> deactivateProfessor(String professorId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/professors/$professorId/deactivate';
      final response = await _httpClient.patch(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode != 200) {
        throw Exception(
          'Error al desactivar profesor: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// GET /api/tenant/courts
  /// Listar canchas del tenant
  Future<List<TenantCourtModel>> getCourts() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/courts';
      final response = await _httpClient.get(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        final List<dynamic> courtsJson = data['courts'] ?? [];
        return courtsJson
            .map((json) => TenantCourtModel.fromJson(
                  json as Map<String, dynamic>,
                ))
            .toList();
      } else {
        throw Exception(
          'Error al obtener canchas: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// POST /api/tenant/courts
  /// Crear cancha
  Future<TenantCourtModel> createCourt(CreateCourtRequest request) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/courts';
      final response = await _httpClient.post(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TenantCourtModel.fromJson(data);
      } else {
        throw Exception(
          'Error al crear cancha: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// PUT /api/tenant/courts/:id
  /// Actualizar cancha
  Future<TenantCourtModel> updateCourt(
    String courtId,
    UpdateCourtRequest request,
  ) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/courts/$courtId';
      final response = await _httpClient.put(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
        body: json.encode(request.toJson()),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return TenantCourtModel.fromJson(data);
      } else {
        throw Exception(
          'Error al actualizar cancha: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  /// DELETE /api/tenant/courts/:id
  /// Eliminar cancha
  Future<void> deleteCourt(String courtId) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);

      final url = '$_baseUrl/tenant/courts/$courtId';
      final response = await _httpClient.delete(
        Uri.parse(url),
        headers: {'Authorization': 'Bearer $idToken'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Error al eliminar cancha: ${response.statusCode}',
        );
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for TenantAdminService
final tenantAdminServiceProvider = Provider<TenantAdminService>((ref) {
  final httpClient = ref.watch(appHttpClientProvider);
  return TenantAdminService(httpClient);
});


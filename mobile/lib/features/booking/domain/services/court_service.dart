import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/services/http_client.dart';
import '../models/court_model.dart';

/// Service for managing court bookings
class CourtService {
  final String _baseUrl = AppConfig.apiBaseUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final AppHttpClient _http;

  CourtService(this._http);

  /// Get list of available courts for the active tenant
  Future<List<CourtModel>> getCourts() async {
    try {
      print('[CourtService] Getting courts...');
      final user = _auth.currentUser;
      if (user == null) {
        print('[CourtService] User is null');
        throw Exception('Usuario no autenticado');
      }

      print('[CourtService] Getting ID token...');
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        print('[CourtService] ID token is null');
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final url = Uri.parse('$_baseUrl/student-dashboard/courts');
      print('[CourtService] Making GET request to: $url');
      
      final response = await _http.get(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
        },
      );

      print('[CourtService] Response status: ${response.statusCode}');
      print('[CourtService] Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final items = data['items'] as List<dynamic>? ?? [];

        print('[CourtService] Parsed ${items.length} courts');
        return items
            .map((item) => CourtModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 400) {
        final error = json.decode(response.body) as Map<String, dynamic>;
        final errorMessage = error['error'] as String? ?? 'Error al obtener canchas';
        print('[CourtService] Error 400: $errorMessage');
        throw Exception(errorMessage);
      } else {
        final errorMessage = 'Error al obtener canchas: ${response.statusCode}';
        print('[CourtService] Error ${response.statusCode}: $errorMessage');
        print('[CourtService] Response body: ${response.body}');
        throw Exception(errorMessage);
      }
    } catch (e, stackTrace) {
      print('[CourtService] Exception caught: $e');
      print('[CourtService] Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Book a court
  Future<Map<String, dynamic>> bookCourt({
    required String courtId,
    required DateTime startTime,
    required DateTime endTime,
    required double price,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await _http.post(
        Uri.parse('$_baseUrl/student-dashboard/book-court'),
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'courtId': courtId,
          'startTime': startTime.toIso8601String(),
          'endTime': endTime.toIso8601String(),
          'price': price,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return json.decode(response.body) as Map<String, dynamic>;
      } else {
        final error = json.decode(response.body) as Map<String, dynamic>;
        throw Exception(error['error'] as String? ?? 'Error al reservar cancha');
      }
    } catch (e) {
      rethrow;
    }
  }
}

/// Provider for CourtService
final courtServiceProvider = Provider<CourtService>((ref) {
  return CourtService(ref.watch(appHttpClientProvider));
});


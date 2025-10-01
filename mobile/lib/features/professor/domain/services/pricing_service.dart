import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class PricingConfig {
  final double individualClass;
  final double groupClass;
  final double courtRental;

  PricingConfig({
    required this.individualClass,
    required this.groupClass,
    required this.courtRental,
  });

  factory PricingConfig.fromJson(Map<String, dynamic> json) {
    return PricingConfig(
      individualClass: (json['individualClass'] as num).toDouble(),
      groupClass: (json['groupClass'] as num).toDouble(),
      courtRental: (json['courtRental'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'individualClass': individualClass,
      'groupClass': groupClass,
      'courtRental': courtRental,
    };
  }
}

class PricingResponse {
  final PricingConfig pricing;
  final PricingConfig customPricing;
  final PricingConfig basePricing;
  final bool hasCustomPricing;

  PricingResponse({
    required this.pricing,
    required this.customPricing,
    required this.basePricing,
    required this.hasCustomPricing,
  });

  factory PricingResponse.fromJson(Map<String, dynamic> json) {
    final customPricingMap = json['customPricing'] as Map<String, dynamic>;
    final basePricingMap = json['basePricing'] as Map<String, dynamic>;

    // If customPricing is empty, use basePricing for all values
    final effectiveCustomPricing = customPricingMap.isEmpty
        ? basePricingMap
        : {
            'individualClass':
                customPricingMap['individualClass'] ??
                basePricingMap['individualClass'],
            'groupClass':
                customPricingMap['groupClass'] ?? basePricingMap['groupClass'],
            'courtRental':
                customPricingMap['courtRental'] ??
                basePricingMap['courtRental'],
          };

    return PricingResponse(
      pricing: PricingConfig.fromJson(json['pricing'] as Map<String, dynamic>),
      customPricing: PricingConfig.fromJson(effectiveCustomPricing),
      basePricing: PricingConfig.fromJson(basePricingMap),
      hasCustomPricing: json['hasCustomPricing'] as bool,
    );
  }
}

class PricingService {
  final String _baseUrl = 'http://192.168.18.6:3000/api';
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Get professor's current pricing
  Future<PricingResponse> getMyPricing() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.get(
        Uri.parse('$_baseUrl/pricing/my-pricing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PricingResponse.fromJson(data);
      } else {
        throw Exception('Error al obtener precios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Update professor's custom pricing
  Future<PricingResponse> updateMyPricing({
    double? individualClass,
    double? groupClass,
    double? courtRental,
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

      final body = <String, dynamic>{};
      if (individualClass != null) body['individualClass'] = individualClass;
      if (groupClass != null) body['groupClass'] = groupClass;
      if (courtRental != null) body['courtRental'] = courtRental;

      final response = await http.put(
        Uri.parse('$_baseUrl/pricing/my-pricing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: json.encode(body),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        print('Parsed data: $data');

        try {
          return PricingResponse.fromJson(data);
        } catch (e) {
          print('Error parsing PricingResponse: $e');
          print('Data keys: ${data.keys}');
          rethrow;
        }
      } else {
        final error = json.decode(response.body);
        throw Exception(error['error'] ?? 'Error al actualizar precios');
      }
    } catch (e) {
      print('Error in updateMyPricing: $e');
      rethrow;
    }
  }

  /// Reset professor's pricing to base pricing
  Future<PricingResponse> resetMyPricing() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('Usuario no autenticado');
      }

      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw Exception('No se pudo obtener el token de autenticación');
      }

      final response = await http.delete(
        Uri.parse('$_baseUrl/pricing/my-pricing'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        return PricingResponse.fromJson(data);
      } else {
        throw Exception('Error al restablecer precios: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }
}

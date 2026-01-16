import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';

import '../../../../core/constants/timeouts.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/logging/logger.dart';

class PaymentService {
  String get _baseUrl => AppConfig.apiBaseUrl;
  final FirebaseAuth _auth;
  final http.Client _httpClient;
  final _logger = AppLogger.tag('PaymentService');

  PaymentService({FirebaseAuth? firebaseAuth, http.Client? httpClient})
    : _auth = firebaseAuth ?? FirebaseAuth.instance,
      _httpClient = httpClient ?? http.Client();

  Future<Map<String, dynamic>> initPayment(
    double amount,
    String tenantId, {
    Map<String, dynamic>? bookingData,
    String? redirectUrl,
  }) async {
    _logger.info('Initializing payment for amount: $amount, tenant: $tenantId');

    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw AuthException.notAuthenticated();
      }

      // IMPORTANTE:
      // Usamos el ID Token de Firebase.
      // El backend DEBE usar firebaseAuthMiddleware en la ruta /payments/init
      // para verificar este token.
      final idToken = await user.getIdToken(true);
      if (idToken == null) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de autenticación',
        );
      }

      final response = await _httpClient
          .post(
            Uri.parse('$_baseUrl/payments/init'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
              'X-Tenant-ID': tenantId,
            },
            body: jsonEncode({
              'amount': amount,
              'currency': 'COP',
              if (bookingData != null) 'bookingInfo': bookingData,
              if (redirectUrl != null) 'redirectUrl': redirectUrl,
            }),
          )
          .timeout(Timeouts.httpRequest);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _logger.info('Payment initialized successfully', {
          'reference': data['reference'],
        });
        return data;
      } else {
        String errorMessage = 'Error al iniciar pago';
        try {
          final errorData = jsonDecode(response.body);
          errorMessage =
              errorData['error'] ?? errorData['details'] ?? errorMessage;
        } catch (_) {}

        _logger.error('Failed to init payment', error: response.body);
        throw NetworkException.serverError(
          message: errorMessage,
          statusCode: response.statusCode,
        );
      }
    } catch (e, stack) {
      _logger.error('Error initializing payment', error: e, stackTrace: stack);
      if (e is AppException) rethrow;
      throw NetworkException.serverError(message: 'Error de conexión');
    }
  }
}

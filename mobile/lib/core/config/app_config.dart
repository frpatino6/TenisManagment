import 'package:flutter/foundation.dart';

class AppConfig {
  static const String _defaultApiUrl = 'http://localhost:3000/api';
  static const String _defaultAuthUrl = 'http://localhost:3000/api/auth';

  // URLs de producción
  static const String _productionApiUrl =
      'https://tenismanagment.onrender.com/api';
  static const String _productionAuthUrl =
      'https://tenismanagment.onrender.com/api/auth';

  // URLs de desarrollo (puedes cambiar estas por tu IP local)
  static const String _developmentApiUrl = 'http://192.168.18.6:3000/api';
  static const String _developmentAuthUrl = 'http://192.168.18.6:3000/api/auth';

  /// Obtiene la URL base de la API según el ambiente
  static String get apiBaseUrl {
    if (kIsWeb) {
      // En web, detectamos el ambiente por la URL
      final hostname = Uri.base.host;

      if (hostname == 'tennis-management-fcd54.web.app' ||
          hostname == 'localhost' && Uri.base.port == 8080) {
        // Producción o desarrollo local
        return _productionApiUrl;
      } else {
        // Desarrollo con IP específica
        return _developmentApiUrl;
      }
    } else {
      // En móvil, usar configuración de debug/release
      if (kDebugMode) {
        return _developmentApiUrl;
      } else {
        return _productionApiUrl;
      }
    }
  }

  /// Obtiene la URL base de autenticación según el ambiente
  static String get authBaseUrl {
    if (kIsWeb) {
      final hostname = Uri.base.host;

      if (hostname == 'tennis-management-fcd54.web.app' ||
          hostname == 'localhost' && Uri.base.port == 8080) {
        return _productionAuthUrl;
      } else {
        return _developmentAuthUrl;
      }
    } else {
      if (kDebugMode) {
        return _developmentAuthUrl;
      } else {
        return _productionAuthUrl;
      }
    }
  }

  /// Obtiene el ambiente actual
  static String get environment {
    if (kIsWeb) {
      final hostname = Uri.base.host;
      if (hostname == 'tennis-management-fcd54.web.app') {
        return 'production';
      } else if (hostname == 'localhost') {
        return 'development';
      } else {
        return 'staging';
      }
    } else {
      return kDebugMode ? 'development' : 'production';
    }
  }
}

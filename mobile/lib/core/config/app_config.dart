class AppConfig {
  /// Obtiene la URL base de la API
  static String get apiBaseUrl {
    // Obtener la URL del backend desde variables de entorno o usar la URL de producción
    const String backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'https://tenismanagment.onrender.com',
    );
    return '$backendUrl/api';
  }

  /// Obtiene la URL base de autenticación
  static String get authBaseUrl {
    const String backendUrl = String.fromEnvironment(
      'BACKEND_URL',
      defaultValue: 'https://tenismanagment.onrender.com',
    );
    return '$backendUrl/api/auth';
  }

  /// Obtiene el ambiente actual
  static String get environment {
    return const String.fromEnvironment(
      'ENVIRONMENT',
      defaultValue: 'production',
    );
  }
}

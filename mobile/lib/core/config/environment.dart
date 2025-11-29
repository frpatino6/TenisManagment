/// Enumeración de ambientes disponibles en la aplicación
/// 
/// Cada ambiente representa una configuración diferente de:
/// - Backend URL
/// - Firebase Project
/// - Configuración de debugging
/// - Nombre de la aplicación
enum Environment {
  /// Ambiente de desarrollo
  /// - Backend: Local (http://10.0.2.2:3000)
  /// - Firebase: tennis-management-dev
  /// - Debug logs: Habilitados
  development,

  /// Ambiente de producción
  /// - Backend: Render (https://tenismanagment.onrender.com)
  /// - Firebase: tennis-management-fcd54
  /// - Debug logs: Deshabilitados
  production;

  /// Verifica si el ambiente actual es desarrollo
  bool get isDevelopment => this == Environment.development;

  /// Verifica si el ambiente actual es producción
  bool get isProduction => this == Environment.production;

  /// Obtiene el nombre legible del ambiente
  String get name {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
    }
  }

  /// Obtiene el nombre corto del ambiente (para logging)
  String get shortName {
    switch (this) {
      case Environment.development:
        return 'dev';
      case Environment.production:
        return 'prod';
    }
  }

  /// Obtiene el identificador del ambiente (para Firebase Analytics, etc.)
  String get identifier {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.production:
        return 'production';
    }
  }
}


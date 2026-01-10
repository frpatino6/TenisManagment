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
  production,

  /// Ambiente de UAT
  /// - Backend: Render UAT (https://tenismanagment-uat.onrender.com)
  /// - Firebase: tennis-management-fcd54
  /// - Debug logs: Habilitados
  uat;

  /// Verifica si el ambiente actual es desarrollo
  bool get isDevelopment => this == Environment.development;

  /// Verifica si el ambiente actual es producción
  bool get isProduction => this == Environment.production;

  /// Verifica si el ambiente actual es UAT
  bool get isUat => this == Environment.uat;

  /// Obtiene el nombre legible del ambiente
  String get name {
    switch (this) {
      case Environment.development:
        return 'Development';
      case Environment.production:
        return 'Production';
      case Environment.uat:
        return 'UAT';
    }
  }

  /// Obtiene el nombre corto del ambiente (para logging)
  String get shortName {
    switch (this) {
      case Environment.development:
        return 'dev';
      case Environment.production:
        return 'prod';
      case Environment.uat:
        return 'uat';
    }
  }

  /// Obtiene el identificador del ambiente (para Firebase Analytics, etc.)
  String get identifier {
    switch (this) {
      case Environment.development:
        return 'development';
      case Environment.production:
        return 'production';
      case Environment.uat:
        return 'uat';
    }
  }
}

/// Constantes centralizadas para mensajes de error user-friendly
///
/// Todos los mensajes de error mostrados al usuario deben estar aquí
/// para facilitar su modificación, traducción y mantenimiento.
class ErrorMessages {
  ErrorMessages._();

  // ============================================
  // Authentication Errors
  // ============================================

  static const String notAuthenticated =
      'Usuario no autenticado. Por favor, inicia sesión.';
  static const String invalidCredentials = 'Email o contraseña incorrectos.';
  static const String tokenExpired =
      'Tu sesión ha expirado. Por favor, inicia sesión nuevamente.';
  static const String userNotFound =
      'Usuario no encontrado. Por favor, regístrate primero.';
  static const String emailAlreadyExists =
      'Este email ya está registrado. Inicia sesión o usa otro email.';
  static const String userDisabled = 'Esta cuenta ha sido deshabilitada.';
  static const String operationNotAllowed =
      'La operación de autenticación no está permitida.';
  static const String googleSignInCancelled =
      'Inicio de sesión con Google cancelado';
  static const String googleSignInFailed =
      'No se pudo iniciar sesión con Google';
  static const String googleTokenError =
      'No se pudo obtener el token de Google';
  static const String firebaseTokenError =
      'No se pudo obtener el token de Firebase. Por favor, intenta iniciar sesión nuevamente.';

  // ============================================
  // Network Errors
  // ============================================

  static const String networkTimeout =
      'La solicitud tardó demasiado. Verifica tu conexión.';
  static const String noConnection =
      'Sin conexión a internet. Verifica tu conexión.';
  static const String serverError = 'Error del servidor. Intenta más tarde.';
  static const String serverUnavailable =
      'El servidor no está disponible. Intenta más tarde.';
  static const String badResponse = 'Error en la respuesta del servidor.';

  // ============================================
  // Validation Errors
  // ============================================

  static const String invalidField = 'Error de validación';
  static const String missingRequiredField = 'Faltan campos requeridos';
  static const String fieldRequired = 'Este campo es requerido';
  static const String invalidEmail = 'El formato del email es inválido';
  static const String weakPassword =
      'La contraseña es muy débil. Debe tener al menos 6 caracteres';
  static const String invalidPhone = 'El formato del teléfono es inválido';

  // ============================================
  // Domain Errors
  // ============================================

  static const String resourceNotFound = 'Recurso no encontrado';
  static const String conflict = 'Conflicto de datos';
  static const String unauthorized =
      'No tienes permisos para realizar esta acción.';
  static const String operationNotAllowedDomain =
      'La operación no está permitida.';

  // ============================================
  // Schedule Errors
  // ============================================

  static const String scheduleConflict =
      'Ya tienes un horario a esta hora en otro centro';
  static const String scheduleNotFound = 'Horario no encontrado';
  static const String scheduleCreationFailed =
      'Error al crear horario: conflicto de horarios';

  // ============================================
  // Tenant Errors
  // ============================================

  static const String tenantNotFound = 'Centro no encontrado';
  static const String tenantJoinFailed =
      'No se pudo unir al centro. Intenta nuevamente.';

  // ============================================
  // Generic Errors
  // ============================================

  static const String unknownError =
      'Ha ocurrido un error inesperado. Intenta nuevamente.';
  static const String connectionError =
      'Error de conexión. Verifica tu internet.';
  static const String timeoutError =
      'La operación tardó demasiado. Intenta nuevamente.';

  // ============================================
  // Helper Methods
  // ============================================

  /// Genera mensaje de recurso no encontrado
  static String resourceNotFoundWithId(String resource, String id) {
    return '$resource con ID "$id" no encontrado';
  }

  /// Genera mensaje de recurso no encontrado sin ID
  static String resourceNotFoundGeneric(String resource) {
    return '$resource no encontrado';
  }

  /// Genera mensaje de error de servidor con código
  static String serverErrorWithCode(int statusCode) {
    return 'Error del servidor (Código: $statusCode).';
  }

  /// Genera mensaje de campo inválido
  static String invalidFieldMessage(String fieldName, String reason) {
    return 'El campo "$fieldName" es inválido: $reason';
  }
}

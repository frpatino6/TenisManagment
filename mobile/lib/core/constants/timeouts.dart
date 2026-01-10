/// Constantes de timeouts para toda la aplicación
///
/// Centraliza todos los tiempos de espera para facilitar su modificación
/// y mantener consistencia en toda la aplicación.
class Timeouts {
  Timeouts._();

  // ============================================
  // HTTP Request Timeouts
  // ============================================

  /// Timeout para requests HTTP estándar
  /// Usado en la mayoría de servicios
  static const Duration httpRequest = Duration(seconds: 30);

  /// Timeout para requests HTTP largos (analytics, reportes, etc.)
  static const Duration httpRequestLong = Duration(seconds: 30);

  /// Timeout para requests HTTP cortos (health checks, etc.)
  static const Duration httpRequestShort = Duration(seconds: 5);

  // ============================================
  // UI/Animation Timeouts
  // ============================================

  /// Duración para mostrar mensajes de éxito (SnackBar)
  static const Duration snackbarSuccess = Duration(seconds: 2);

  /// Duración para mostrar mensajes de error (SnackBar)
  static const Duration snackbarError = Duration(seconds: 3);

  /// Duración para mostrar mensajes informativos (SnackBar)
  static const Duration snackbarInfo = Duration(seconds: 2);

  /// Delay corto para animaciones/transiciones
  static const Duration animationShort = Duration(milliseconds: 100);

  /// Delay medio para animaciones/transiciones
  static const Duration animationMedium = Duration(milliseconds: 200);

  /// Delay largo para animaciones/transiciones
  static const Duration animationLong = Duration(milliseconds: 300);

  /// Delay extra largo para animaciones/transiciones
  static const Duration animationExtraLong = Duration(milliseconds: 500);

  // ============================================
  // Debounce/Delay Timeouts
  // ============================================

  /// Delay para debounce de búsqueda
  static const Duration debounceSearch = Duration(milliseconds: 400);

  /// Delay para esperar antes de mostrar loading
  static const Duration loadingDelay = Duration(milliseconds: 200);

  /// Delay para esperar antes de ocultar loading
  static const Duration loadingHideDelay = Duration(milliseconds: 500);

  // ============================================
  // Specific Use Cases
  // ============================================

  /// Delay para esperar token de Firebase
  static const Duration firebaseTokenDelay = Duration(milliseconds: 100);

  /// Timeout para diálogos de confirmación
  static const Duration dialogTimeout = Duration(seconds: 5);

  /// Delay para animaciones de carga (shimmer, skeleton)
  static const Duration shimmerAnimation = Duration(milliseconds: 1500);

  /// Delay para animaciones de métricas
  static const Duration metricAnimation = Duration(milliseconds: 2000);

  /// Delay para animaciones de gráficos
  static const Duration chartAnimation = Duration(milliseconds: 800);

  /// Delay para animaciones de widgets
  static const Duration widgetAnimation = Duration(milliseconds: 1000);
}

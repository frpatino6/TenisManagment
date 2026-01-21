// Stub para móvil - este archivo se usa cuando NO se compila para web
/// Utilidades para web (stub para móvil)
class WebUtils {
  static void reloadPage() {
    // No hace nada en móvil
  }

  /// Stub for mobile - does nothing
  static void openUrl(String url, {bool newTab = false}) {
    // No hace nada en móvil
  }

  /// Stub for mobile - does nothing
  static void addWindowFocusListener(void Function() callback) {
    // No hace nada en móvil
  }

  /// Stub for mobile - does nothing
  static void Function() addWindowFocusListenerWithDispose(
    void Function() callback,
  ) {
    return () {};
  }

  /// Stub for mobile - does nothing
  static void removeWindowFocusListener(void Function() callback) {
    // No hace nada en móvil
  }

  /// Stub for mobile - does nothing
  static void Function() addWindowMessageListener(
    void Function(String message) callback,
  ) {
    return () {};
  }

  /// Stub for mobile - does nothing
  static void Function() addWindowStorageListener(
    void Function(String key, String? value) callback,
  ) {
    return () {};
  }

  static void removeLocalStorageItem(String key) {}
}

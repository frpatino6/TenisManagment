// Implementación para web - este archivo se usa cuando se compila para web
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Utilidades para web
class WebUtils {
  static void reloadPage() {
    web.window.location.reload();
  }

  /// Add listener for window focus events (when user returns to tab)
  static void addWindowFocusListener(void Function() callback) {
    web.window.addEventListener('focus', callback.toJS);
  }

  /// Remove window focus listener
  static void removeWindowFocusListener(void Function() callback) {
    web.window.removeEventListener('focus', callback.toJS);
  }
}

// Implementación para web - este archivo se usa cuando se compila para web
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Utilidades para web
class WebUtils {
  static void reloadPage() {
    web.window.location.reload();
  }

  /// Open a URL in the same window (prevents popup blockers on mobile Safari)
  static void openUrl(String url) {
    web.window.location.assign(url);
  }

  /// Add listener for window focus events and visibility changes (when user returns to tab)
  static void addWindowFocusListener(void Function() callback) {
    web.window.addEventListener('focus', callback.toJS);
    web.document.addEventListener(
      'visibilitychange',
      ((web.Event e) {
        if (web.document.visibilityState == 'visible') {
          callback();
        }
      }).toJS,
    );
  }

  /// Remove window focus listener
  static void removeWindowFocusListener(void Function() callback) {
    web.window.removeEventListener('focus', callback.toJS);
    // Note: removing visibilitychange listener is more complex if not stored,
    // but in main_common it lasts for the app life.
  }
}

// Implementación para web - este archivo se usa cuando se compila para web
import 'package:web/web.dart' as web;
import 'dart:js_interop';

/// Utilidades para web
class WebUtils {
  static void reloadPage() {
    web.window.location.reload();
  }

  /// Open a URL (prevents popup blockers on mobile Safari if used in direct interaction)
  static void openUrl(String url, {bool newTab = false}) {
    if (newTab) {
      web.window.open(url, '_blank');
    } else {
      web.window.location.assign(url);
    }
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

  /// Add listener for window focus events with disposer
  static void Function() addWindowFocusListenerWithDispose(
    void Function() callback,
  ) {
    final jsFocusListener = callback.toJS;
    final jsVisibilityListener = ((web.Event e) {
      if (web.document.visibilityState == 'visible') {
        callback();
      }
    }).toJS;

    web.window.addEventListener('focus', jsFocusListener);
    web.document.addEventListener('visibilitychange', jsVisibilityListener);

    return () {
      web.window.removeEventListener('focus', jsFocusListener);
      web.document.removeEventListener('visibilitychange', jsVisibilityListener);
    };
  }

  /// Add listener for window message events (postMessage)
  static void Function() addWindowMessageListener(
    void Function(String message) callback,
  ) {
    final jsListener = ((web.MessageEvent event) {
      final data = event.data;
      if (data != null) {
        callback(data.toString());
      }
    }).toJS;

    web.window.addEventListener('message', jsListener);
    return () => web.window.removeEventListener('message', jsListener);
  }

  /// Add listener for localStorage changes (storage events)
  static void Function() addWindowStorageListener(
    void Function(String key, String? value) callback,
  ) {
    final jsListener = ((web.StorageEvent event) {
      final key = event.key;
      if (key != null) {
        callback(key, event.newValue);
      }
    }).toJS;

    web.window.addEventListener('storage', jsListener);
    return () => web.window.removeEventListener('storage', jsListener);
  }

  static void removeLocalStorageItem(String key) {
    web.window.localStorage.removeItem(key);
  }
}

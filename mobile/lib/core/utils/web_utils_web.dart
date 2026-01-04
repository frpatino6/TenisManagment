// Implementación para web - este archivo se usa cuando se compila para web
import 'dart:html' as html;

/// Utilidades para web
class WebUtils {
  static void reloadPage() {
    html.window.location.reload();
  }
}

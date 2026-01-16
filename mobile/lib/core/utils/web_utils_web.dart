// Implementación para web - este archivo se usa cuando se compila para web
import 'package:web/web.dart' as web;

/// Utilidades para web
class WebUtils {
  static void reloadPage() {
    web.window.location.reload();
  }
}

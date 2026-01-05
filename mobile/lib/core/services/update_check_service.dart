import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';
import '../constants/timeouts.dart';
import 'version_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateCheckResult {
  final bool updateRequired;
  final bool forceUpdate;
  final String minVersion;
  final String currentVersion;

  UpdateCheckResult({
    required this.updateRequired,
    required this.forceUpdate,
    required this.minVersion,
    required this.currentVersion,
  });
}

class UpdateCheckService {
  static const String _lastCheckKey = 'last_update_check';
  static const String _lastCheckVersionKey = 'last_check_version';
  static const Duration _checkInterval = Duration(hours: 24);

  static UpdateCheckService? _instance;
  static UpdateCheckService get instance =>
      _instance ??= UpdateCheckService._();

  UpdateCheckService._();

  /// Verifica si hay una actualización disponible
  /// Retorna null si hay error de red (permite continuar)
  Future<UpdateCheckResult?> checkForUpdate() async {
    try {
      final versionService = VersionService.instance;
      final currentVersion = versionService.version;

      // Verificar si ya se hizo check recientemente con la misma versión
      final prefs = await SharedPreferences.getInstance();
      final lastCheck = prefs.getString(_lastCheckKey);
      final lastCheckVersion = prefs.getString(_lastCheckVersionKey);

      // Si cambió la versión de la app, forzar nueva verificación
      if (lastCheck != null && lastCheckVersion == currentVersion) {
        final lastCheckTime = DateTime.parse(lastCheck);
        final now = DateTime.now();
        if (now.difference(lastCheckTime) < _checkInterval) {
          // Ya se verificó recientemente, no hacer otra petición
          // PERO: si hay una actualización pendiente, debemos verificar de nuevo
          // Por ahora, permitimos verificar siempre para asegurar que se detecten actualizaciones
          // return null;
        }
      }

      final response = await http
          .get(
            Uri.parse('${AppConfig.apiBaseUrl}/config/version'),
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(Timeouts.httpRequestShort);

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        final minVersion = data['minVersion'] as String? ?? currentVersion;
        final serverVersion =
            data['currentVersion'] as String? ?? currentVersion;
        final forceUpdate = data['forceUpdate'] as bool? ?? false;

        // Comparar versiones: se requiere actualización si la versión actual es MENOR que la mínima requerida
        final updateRequired = versionService.isVersionLessThan(minVersion);

        // Guardar que se hizo el check SOLO si NO se requiere actualización
        // Si se requiere actualización, no guardamos el cache para que siga verificando
        if (!updateRequired) {
          await prefs.setString(
            _lastCheckKey,
            DateTime.now().toIso8601String(),
          );
          await prefs.setString(_lastCheckVersionKey, currentVersion);
        }

        return UpdateCheckResult(
          updateRequired: updateRequired,
          forceUpdate: forceUpdate,
          minVersion: minVersion,
          currentVersion: serverVersion,
        );
      }

      // Si hay error, retornar null para permitir continuar
      return null;
    } catch (e) {
      // En caso de error de red, permitir continuar
      return null;
    }
  }

  /// Limpia el cache de última verificación (útil para forzar nueva verificación)
  Future<void> clearLastCheck() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_lastCheckKey);
    await prefs.remove(_lastCheckVersionKey);
  }
}

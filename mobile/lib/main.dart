/// Entrypoint por defecto de la aplicación
///
/// Este archivo simplemente importa y ejecuta main_prod.dart
/// para mantener compatibilidad con comandos estándar de Flutter.
///
/// Al ejecutar `flutter run` sin especificar el target,
/// se usará este archivo que apunta a producción.
///
/// Para desarrollo, usa:
/// - flutter run --flavor dev -t lib/main_dev.dart
/// - ./scripts/run_dev.sh
library;

export 'main_prod.dart';

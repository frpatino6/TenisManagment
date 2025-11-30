import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core/firebase_core.dart' show FirebaseException;
import 'core/config/environment.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_config.dart';
import 'main_common.dart';

/// Entrypoint para el ambiente de DESARROLLO
/// 
/// Este es el punto de entrada cuando ejecutas:
/// - flutter run --flavor dev -t lib/main_dev.dart
/// - ./scripts/run_dev.sh
/// 
/// Configuración:
/// - Backend: http://10.0.2.2:3000 (localhost en emulador Android)
/// - Firebase: tennis-management-fcd54 (por ahora, cambiar cuando crees proyecto dev)
/// - Debug logs: Habilitados
/// - App name: "Tennis DEV"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 IMPORTANTE: Establecer el ambiente ANTES de cualquier otra inicialización
  AppConfig.setEnvironment(Environment.development);

  // Imprimir configuración en consola (solo en modo debug)
  AppConfig.printConfig();

  // Inicializar Firebase con la configuración de desarrollo
  try {
    // Intentar inicializar Firebase
    await Firebase.initializeApp(
      options: FirebaseConfig.developmentOptions,
    );
    debugPrint('✅ Firebase initialized for DEVELOPMENT');
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      // Firebase ya está inicializado (probablemente por plugin nativo)
      debugPrint('✅ Firebase ya estaba inicializado');
    } else {
      debugPrint('⚠️ Firebase error: ${e.code} - ${e.message}');
    }
  } catch (e) {
    debugPrint('⚠️ Error al inicializar Firebase: $e');
  }

  // Ejecutar la aplicación
  runApp(const ProviderScope(child: TennisManagementApp()));
}


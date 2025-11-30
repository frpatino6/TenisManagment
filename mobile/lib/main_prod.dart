import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_config.dart';
import 'main_common.dart';

/// Entrypoint para el ambiente de PRODUCCIÓN
/// 
/// Este es el punto de entrada cuando ejecutas:
/// - flutter run --flavor prod -t lib/main_prod.dart
/// - flutter run (por defecto via main.dart)
/// - ./scripts/run_prod.sh
/// 
/// Configuración:
/// - Backend: https://tenismanagment.onrender.com
/// - Firebase: tennis-management-fcd54
/// - Debug logs: Deshabilitados
/// - App name: "Tennis Management"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🎯 IMPORTANTE: Establecer el ambiente ANTES de cualquier otra inicialización
  AppConfig.setEnvironment(Environment.production);

  // Imprimir configuración en consola (solo en modo debug)
  AppConfig.printConfig();

  // Inicializar Firebase con la configuración de producción
  try {
    // Intentar inicializar Firebase
    await Firebase.initializeApp(
      options: FirebaseConfig.productionOptions,
    );
    debugPrint('✅ Firebase initialized for PRODUCTION');
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


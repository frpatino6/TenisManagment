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

  AppConfig.setEnvironment(Environment.production);

  try {
    await Firebase.initializeApp(options: FirebaseConfig.productionOptions);
  } on FirebaseException {
    // Firebase already initialized
  } catch (_) {
    // Error initializing Firebase
  }

  runApp(const ProviderScope(child: TennisManagementApp()));
}

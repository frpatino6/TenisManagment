import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'core/config/environment.dart';
import 'core/config/app_config.dart';
import 'core/config/firebase_config.dart';
import 'main_common.dart';

/// Entrypoint para el ambiente de UAT
///
/// Este es el punto de entrada cuando ejecutas:
/// - flutter run --flavor uat -t lib/main_uat.dart
/// - ./scripts/run_uat.sh
///
/// Configuración:
/// - Backend: https://tenis-uat.casacam.net
/// - Firebase: tennis-management-fcd54 (Mismo que prod por ahora)
/// - Debug logs: Habilitados
/// - App name: "Tennis UAT"
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppConfig.setEnvironment(Environment.uat);

  try {
    await Firebase.initializeApp(options: FirebaseConfig.productionOptions);
  } on FirebaseException {
    // Firebase already initialized
  } catch (_) {
    // Error initializing Firebase
  }

  runApp(const ProviderScope(child: TennisManagementApp()));
}

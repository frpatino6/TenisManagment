import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
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

  AppConfig.setEnvironment(Environment.development);

  try {
    await Firebase.initializeApp(options: FirebaseConfig.developmentOptions);
  } on FirebaseException catch (e) {

  } catch (e) {

  }

  runApp(const ProviderScope(child: TennisManagementApp()));
}

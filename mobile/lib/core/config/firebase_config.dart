import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'environment.dart';
import 'app_config.dart';

/// Configuración de Firebase por ambiente
///
/// Este archivo maneja las opciones de Firebase específicas para cada ambiente.
///
/// NOTA: Actualmente ambos ambientes usan el mismo proyecto Firebase.
/// En el futuro, se puede crear un proyecto separado para desarrollo:
/// - Development: tennis-management-dev
/// - Production: tennis-management-fcd54 (actual)
class FirebaseConfig {
  /// Obtiene las opciones de Firebase según el ambiente actual
  static FirebaseOptions get currentOptions {
    final env = AppConfig.environment;

    switch (env) {
      case Environment.development:
        return developmentOptions;
      case Environment.production:
        return productionOptions;
      case Environment.uat:
        // Por ahora UAT usa las mismas opciones que Prod (o Dev), apuntando al mismo proyecto Firebase
        // Si se crea un proyecto 'tennis-management-uat', se usaría uatOptions
        return productionOptions;
    }
  }

  static FirebaseOptions get developmentOptions {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
        appId: '1:147485418255:web:666307bde5041b33ae147a',
        messagingSenderId: '147485418255',
        projectId: 'tennis-management-fcd54',
        authDomain: 'tennis-management-fcd54.firebaseapp.com',
        storageBucket: 'tennis-management-fcd54.appspot.com',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
          appId: '1:147485418255:android:391210836c25854eae147a',
          messagingSenderId: '147485418255',
          projectId: 'tennis-management-fcd54',
          storageBucket: 'tennis-management-fcd54.appspot.com',
        );

      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
          appId: '1:147485418255:ios:391210836c25854eae147a', // Placeholder
          messagingSenderId: '147485418255',
          projectId: 'tennis-management-fcd54',
          storageBucket: 'tennis-management-fcd54.appspot.com',
          iosBundleId: 'com.tennismanagement.tennisManagement',
        );

      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
          appId: '1:147485418255:ios:391210836c25854eae147a', // Placeholder
          messagingSenderId: '147485418255',
          projectId: 'tennis-management-fcd54',
          storageBucket: 'tennis-management-fcd54.appspot.com',
          iosBundleId: 'com.tennismanagement.tennisManagement',
        );

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  /// Opciones de Firebase para producción
  static FirebaseOptions get productionOptions {
    if (kIsWeb) {
      return const FirebaseOptions(
        apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
        appId: '1:147485418255:web:666307bde5041b33ae147a',
        messagingSenderId: '147485418255',
        projectId: 'tennis-management-fcd54',
        authDomain: 'tennis-management-fcd54.firebaseapp.com',
        storageBucket: 'tennis-management-fcd54.appspot.com',
      );
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
          appId: '1:147485418255:android:391210836c25854eae147a',
          messagingSenderId: '147485418255',
          projectId: 'tennis-management-fcd54',
          storageBucket: 'tennis-management-fcd54.appspot.com',
        );

      case TargetPlatform.iOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
          appId: '1:147485418255:ios:391210836c25854eae147a', // Placeholder
          messagingSenderId: '147485418255',
          projectId: 'tennis-management-fcd54',
          storageBucket: 'tennis-management-fcd54.appspot.com',
          iosBundleId: 'com.tennismanagement.tennisManagement',
        );

      case TargetPlatform.macOS:
        return const FirebaseOptions(
          apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
          appId: '1:147485418255:ios:391210836c25854eae147a', // Placeholder
          messagingSenderId: '147485418255',
          projectId: 'tennis-management-fcd54',
          storageBucket: 'tennis-management-fcd54.appspot.com',
          iosBundleId: 'com.tennismanagement.tennisManagement',
        );

      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }
}

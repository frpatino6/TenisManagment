

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
    appId: '1:147485418255:web:666307bde5041b33ae147a',
    messagingSenderId: '147485418255',
    projectId: 'tennis-management-fcd54',
    authDomain: 'tennis-management-fcd54.firebaseapp.com',
    storageBucket: 'tennis-management-fcd54.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCpTj2lrD-ew7oB-FlByrv9JVbb9FTwfQQ',
    appId: '1:147485418255:android:391210836c25854eae147a',
    messagingSenderId: '147485418255',
    projectId: 'tennis-management-fcd54',
    storageBucket: 'tennis-management-fcd54.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC...', // Reemplazar con tu API key de iOS
    appId: '1:147485418255:ios:...', // Reemplazar con tu App ID de iOS
    messagingSenderId: '147485418255',
    projectId: 'tennis-management-fcd54',
    storageBucket: 'tennis-management-fcd54.appspot.com',
    iosBundleId: 'com.tennismanagement.tennisManagement',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyC...', // Reemplazar con tu API key de macOS
    appId: '1:147485418255:ios:...', // Reemplazar con tu App ID de macOS
    messagingSenderId: '147485418255',
    projectId: 'tennis-management-fcd54',
    storageBucket: 'tennis-management-fcd54.appspot.com',
    iosBundleId: 'com.tennismanagement.tennisManagement',
  );
}

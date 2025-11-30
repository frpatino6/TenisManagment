import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import '../../../../core/config/app_config.dart';
import '../models/user_model.dart';

/// Service responsible for user authentication operations
/// Handles Firebase Auth, Google Sign-In, and backend API communication
/// Manages user session state and authentication flows
class AuthService {
  String get _baseUrl => AppConfig.authBaseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  bool get isAuthenticated => currentFirebaseUser != null;

  /// Initiates Google Sign-In authentication flow
  /// Returns [UserModel] with user data from backend
  /// Throws [Exception] if authentication fails or is cancelled
  Future<UserModel> signInWithGoogle() async {
    try {
      debugPrint('🔵 Iniciando Google Sign-In...');
      User? user;

      if (kIsWeb) {
        debugPrint('🌐 Modo Web detectado');
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final UserCredential userCredential = await _firebaseAuth
            .signInWithPopup(provider);
        user = userCredential.user;
      } else {
        debugPrint('📱 Modo móvil detectado');
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          debugPrint('❌ Google Sign-In cancelado por el usuario');
          throw Exception('Google Sign-In was cancelled');
        }

        debugPrint('✅ Google Sign-In exitoso: ${googleUser.email}');
        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          debugPrint('❌ No se obtuvo idToken de Google');
          throw Exception('Failed to get ID token from Google');
        }

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        debugPrint('🔥 Autenticando con Firebase...');
        final UserCredential userCredential = await _firebaseAuth
            .signInWithCredential(credential);
        user = userCredential.user;
        debugPrint('✅ Firebase auth exitoso: ${user?.email}');
      }

      if (user == null) {
        debugPrint('❌ Usuario de Firebase es null');
        throw Exception('Failed to sign in with Google');
      }

      // Autenticar con el backend
      debugPrint('🔄 Autenticando con backend...');
      final UserModel userModel = await _authenticateWithBackend(user);
      debugPrint('✅ Autenticación completa: ${userModel.email}');
      return userModel;
    } catch (e, stackTrace) {
      debugPrint('💥 Error en signInWithGoogle: $e');
      debugPrint('📚 Stack trace: $stackTrace');
      rethrow;
    }
  }

  // Iniciar sesión con email y contraseña
  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      // Iniciar sesión con Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithEmailAndPassword(email: email, password: password);

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('Failed to sign in with email');
      }

      // Autenticar con el backend
      final UserModel userModel = await _authenticateWithBackend(user);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Registrarse con email y contraseña
  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      UserCredential userCredential;
      User? user;

      try {
        // 1. Intentar crear usuario en Firebase
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // Si el email ya está en uso, intentar iniciar sesión
          userCredential = await _firebaseAuth.signInWithEmailAndPassword(
            email: email,
            password: password,
          );
          user = userCredential.user;
        } else {
          rethrow; // Re-lanzar otras excepciones de Firebase
        }
      }

      if (user == null) {
        throw Exception('Failed to register or sign in with Firebase');
      }

      // 2. Actualizar el perfil del usuario si es nuevo
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      // 3. Registrar en el backend con el rol correcto
      final UserModel userModel = await _registerWithBackend(
        name: name,
        email: email,
        phone: phone,
        role: role,
        firebaseUid: user.uid,
      );

      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        // En web solo es necesario cerrar sesión en Firebase
        await _firebaseAuth.signOut();
      } else {
        await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Obtener información del usuario autenticado
  Future<UserModel> getUserInfo() async {
    try {
      final User? user = currentFirebaseUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final idToken = await user.getIdToken(true); // Force refresh

      final response = await http.get(
        Uri.parse('$_baseUrl/firebase/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Autenticar con el backend usando Firebase ID token
  Future<UserModel> _authenticateWithBackend(User user) async {
    try {
      final String idToken = await user.getIdToken() ?? '';
      
      if (idToken.isEmpty) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      // TEMPORAL: Imprimir token para Postman
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('🔥 TOKEN FIREBASE PARA POSTMAN (copia esto):');
      debugPrint(idToken);
      debugPrint('═══════════════════════════════════════════════════════');

      final url = Uri.parse('$_baseUrl/firebase/verify');
      debugPrint('🔐 Autenticando con backend: $url');
      
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      debugPrint('📡 Respuesta del backend: ${response.statusCode}');
      debugPrint('📄 Body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        final errorBody = response.body;
        debugPrint('❌ Error del backend: $errorBody');
        throw Exception('Backend authentication failed: ${response.statusCode} - $errorBody');
      }
    } catch (e) {
      debugPrint('💥 Error en _authenticateWithBackend: $e');
      rethrow;
    }
  }

  // Registrar usuario en el backend
  Future<UserModel> _registerWithBackend({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String firebaseUid,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/firebase/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'phone': phone,
          'role': role,
          'firebaseUid': firebaseUid,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw Exception('Failed to register user: ${response.statusCode}');
      }
    } catch (e) {
      rethrow;
    }
  }

  // Enviar email de verificación
  Future<void> sendEmailVerification() async {
    try {
      final User? user = currentFirebaseUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
      }
    } catch (e) {
      rethrow;
    }
  }

  // Enviar email de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  // Verificar si el email está verificado
  bool get isEmailVerified => currentFirebaseUser?.emailVerified ?? false;

  // Obtener el email del usuario actual
  String? get currentUserEmail => currentFirebaseUser?.email;

  // Obtener el nombre del usuario actual
  String? get currentUserName => currentFirebaseUser?.displayName;
}

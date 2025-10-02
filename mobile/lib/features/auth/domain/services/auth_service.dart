import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/config/app_config.dart';
import '../models/user_model.dart';

class AuthService {
  String get _baseUrl => AppConfig.authBaseUrl;

  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Stream del usuario actual de Firebase
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Usuario actual de Firebase
  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  // Verificar si hay un usuario autenticado
  bool get isAuthenticated => currentFirebaseUser != null;

  // Iniciar sesión con Google
  Future<UserModel> signInWithGoogle() async {
    try {
      User? user;

      if (kIsWeb) {
        // Web: usar popup con Firebase Auth directamente
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final UserCredential userCredential = await _firebaseAuth
            .signInWithPopup(provider);
        user = userCredential.user;
      } else {
        // Mobile/Desktop: usar flujo de google_sign_in + credenciales
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google Sign-In was cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        final OAuthCredential credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );

        final UserCredential userCredential = await _firebaseAuth
            .signInWithCredential(credential);
        user = userCredential.user;
      }

      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Autenticar con el backend
      final UserModel userModel = await _authenticateWithBackend(user);
      return userModel;
    } catch (e) {
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

      final response = await http.post(
        Uri.parse('$_baseUrl/firebase/verify'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'idToken': idToken}),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        throw Exception('Backend authentication failed');
      }
    } catch (e) {
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

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../models/user_model.dart';

class AuthService {
  static const String _baseUrl = 'http://192.168.18.6:3000/api/auth';

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
      // Iniciar el flujo de Google Sign-In
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google Sign-In was cancelled');
      }

      // Obtener los detalles de autenticación
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Crear una nueva credencial
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Iniciar sesión con Firebase
      final UserCredential userCredential = await _firebaseAuth
          .signInWithCredential(credential);
      final User? user = userCredential.user;

      if (user == null) {
        throw Exception('Failed to sign in with Google');
      }

      // Autenticar con el backend
      final UserModel userModel = await _authenticateWithBackend(user);
      return userModel;
    } catch (e) {
      debugPrint('Error signing in with Google: $e');
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
      debugPrint('Error signing in with email: $e');
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
          debugPrint('Email already in use, attempting to sign in instead.');
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
      debugPrint('Error registering with email: $e');
      rethrow;
    }
  }

  // Cerrar sesión
  Future<void> signOut() async {
    try {
      await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
    } catch (e) {
      debugPrint('Error signing out: $e');
      rethrow;
    }
  }

  // Obtener información del usuario autenticado
  Future<UserModel> getUserInfo() async {
    try {
      final User? user = currentFirebaseUser;
      if (user == null) {
        debugPrint('getUserInfo: No user is currently signed in');
        throw Exception('No user is currently signed in');
      }

      debugPrint('getUserInfo: Getting user info for ${user.uid}');
      final idToken = await user.getIdToken(true); // Force refresh
      debugPrint(
        'getUserInfo: Token obtained, length: ${idToken?.length ?? 0}',
      );

      final response = await http.get(
        Uri.parse('$_baseUrl/firebase/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
      );

      debugPrint('getUserInfo: Response status: ${response.statusCode}');
      debugPrint('getUserInfo: Response body: ${response.body}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else {
        throw Exception('Failed to get user info: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error getting user info: $e');
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
        debugPrint('Backend authentication failed: ${response.statusCode}');
        throw Exception('Backend authentication failed');
      }
    } catch (e) {
      debugPrint('Error authenticating with backend: $e');
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
      debugPrint('Error registering with backend: $e');
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
      debugPrint('Error sending email verification: $e');
      rethrow;
    }
  }

  // Enviar email de restablecimiento de contraseña
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      debugPrint('Error sending password reset email: $e');
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

import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
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
      User? user;

      if (kIsWeb) {
        final provider = GoogleAuthProvider();
        provider.setCustomParameters({'prompt': 'select_account'});
        final UserCredential userCredential = await _firebaseAuth
            .signInWithPopup(provider);
        user = userCredential.user;
      } else {
        final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          throw Exception('Google Sign-In was cancelled');
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw Exception('Failed to get ID token from Google');
        }

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

      final UserModel userModel = await _authenticateWithBackend(user);
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    try {
      // Intentar el login
      UserCredential userCredential;
      try {
        userCredential = await _firebaseAuth.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } on FirebaseAuthException catch (e) {
        // Si el error es invalid-credential, puede ser que:
        // 1. El usuario no existe
        // 2. La contraseña es incorrecta
        // 3. El usuario se registró con Google (no tiene contraseña)
        if (e.code == 'invalid-credential' || e.code == 'user-not-found') {
          // Intentar recuperar contraseña para verificar si el usuario existe
          // Si el usuario existe, Firebase enviará el email de recuperación
          // Si no existe, Firebase lanzará un error
          try {
            await _firebaseAuth.sendPasswordResetEmail(email: email);
            throw Exception(
              'La contraseña es incorrecta. Si te registraste con Google, usa "Continuar con Google". Si olvidaste tu contraseña, revisa tu email para restablecerla.',
            );
          } catch (resetError) {
            // Si el error es nuestro Exception personalizado, re-lanzarlo
            if (resetError is Exception &&
                (resetError.toString().contains('Contraseña') ||
                    resetError.toString().contains('Google'))) {
              rethrow;
            }
            // Si falla el envío de recuperación, el usuario probablemente no existe
            throw Exception(
              'No existe una cuenta con este email. Por favor, regístrate primero.',
            );
          }
        }
        rethrow; // Re-lanzar otros errores
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw Exception('No se pudo obtener el usuario después del login');
      }

      try {
        final UserModel userModel = await _authenticateWithBackend(user);
        return userModel;
      } catch (backendError) {
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'wrong-password':
          errorMessage = 'Contraseña incorrecta';
          break;
        case 'user-not-found':
          errorMessage = 'No existe una cuenta con este email';
          break;
        case 'invalid-email':
          errorMessage = 'El formato del email es inválido';
          break;
        case 'user-disabled':
          errorMessage = 'Esta cuenta ha sido deshabilitada';
          break;
        case 'too-many-requests':
          errorMessage = 'Demasiados intentos fallidos. Intenta más tarde';
          break;
        case 'operation-not-allowed':
          errorMessage = 'El método de autenticación no está habilitado';
          break;
        case 'network-request-failed':
          errorMessage = 'Error de conexión. Verifica tu internet';
          break;
        case 'invalid-credential':
          // Este error puede significar:
          // 1. Contraseña incorrecta
          // 2. El usuario se registró con Google (no tiene contraseña)
          errorMessage =
              'Email o contraseña incorrectos. Si te registraste con Google, usa "Continuar con Google" para iniciar sesión.';
          break;
        default:
          errorMessage = 'Error de autenticación: ${e.message ?? e.code}';
      }
      throw Exception(errorMessage);
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('credential') ||
          errorStr.contains('incorrect') ||
          errorStr.contains('expired')) {
        throw Exception(
          'Las credenciales son incorrectas. Si te registraste con Google, usa "Continuar con Google" para iniciar sesión.',
        );
      }
      rethrow;
    }
  }

  Future<UserModel> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
    String? tenantId,
  }) async {
    try {
      UserCredential userCredential;
      User? user;

      try {
        userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
        user = userCredential.user;
      } on FirebaseAuthException catch (e) {
        if (e.code == 'email-already-in-use') {
          // El email existe en Firebase, pero puede que no esté en el backend
          // Intentar iniciar sesión para obtener el usuario y verificar en backend
          try {
            userCredential = await _firebaseAuth.signInWithEmailAndPassword(
              email: email,
              password: password,
            );
            user = userCredential.user;

            // Intentar obtener info del backend - si falla, el usuario no existe en backend
            try {
              await getUserInfo();
              throw Exception(
                'Este email ya está registrado. Por favor, usa la pantalla de inicio de sesión.',
              );
            } catch (backendError) {
              // Si falla al obtener info, el usuario no existe en backend
              // Continuar con el registro en backend
            }
          } on FirebaseAuthException catch (loginError) {
            // Si el login falla, la contraseña es incorrecta
            if (loginError.code == 'wrong-password' ||
                loginError.code == 'invalid-credential') {
              throw Exception(
                'Este email ya está registrado pero la contraseña es incorrecta. Por favor, usa la pantalla de inicio de sesión o recupera tu contraseña.',
              );
            }
            rethrow;
          }
        } else {
          String errorMessage;
          switch (e.code) {
            case 'weak-password':
              errorMessage =
                  'La contraseña es muy débil. Debe tener al menos 6 caracteres';
              break;
            case 'invalid-email':
              errorMessage = 'El formato del email es inválido';
              break;
            case 'operation-not-allowed':
              errorMessage =
                  'El registro con email no está habilitado en Firebase';
              break;
            case 'network-request-failed':
              errorMessage = 'Error de conexión. Verifica tu internet';
              break;
            default:
              errorMessage = 'Error al registrar: ${e.message ?? e.code}';
          }
          throw Exception(errorMessage);
        }
      }

      if (user == null) {
        throw Exception('Failed to register or sign in with Firebase');
      }

      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }

      final UserModel userModel = await _registerWithBackend(
        name: name,
        email: email,
        phone: phone,
        role: role,
        firebaseUid: user.uid,
        tenantId: tenantId,
      );
      return userModel;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      if (kIsWeb) {
        await _firebaseAuth.signOut();
      } else {
        await Future.wait([_firebaseAuth.signOut(), _googleSignIn.signOut()]);
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> getUserInfo() async {
    try {
      final User? user = currentFirebaseUser;
      if (user == null) {
        throw Exception('No user is currently signed in');
      }

      final idToken = await user.getIdToken(true) ?? '';
      if (idToken.isEmpty) {
        throw Exception('No se pudo obtener el token de Firebase');
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/firebase/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al obtener información del usuario');
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

  Future<UserModel> _authenticateWithBackend(User user) async {
    try {
      // Esperar un momento para asegurar que el token esté listo
      await Future.delayed(const Duration(milliseconds: 100));

      String idToken;
      try {
        idToken = await user.getIdToken(true) ?? ''; // Force refresh
      } catch (tokenError) {
        // Intentar sin forzar refresh
        idToken = await user.getIdToken() ?? '';
      }

      if (idToken.isEmpty) {
        throw Exception(
          'No se pudo obtener el token de Firebase. Por favor, intenta iniciar sesión nuevamente.',
        );
      }

      final url = Uri.parse('$_baseUrl/firebase/verify');

      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idToken': idToken}),
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              throw Exception('Timeout al conectar con el servidor');
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        final errorBody = response.body;

        String errorMessage;
        try {
          final errorData = json.decode(errorBody);
          errorMessage =
              errorData['error'] ??
              errorData['details'] ??
              'Error de autenticación en el servidor';
        } catch (_) {
          // Si no se puede parsear el JSON, usar el mensaje por defecto según el código
          if (response.statusCode == 401) {
            errorMessage =
                'Token inválido o expirado. Por favor, intenta iniciar sesión nuevamente.';
          } else if (response.statusCode == 404) {
            errorMessage =
                'Usuario no encontrado en el sistema. Por favor, regístrate primero.';
          } else if (response.statusCode == 503) {
            errorMessage =
                'Firebase está deshabilitado en el servidor. Contacta al administrador.';
          } else {
            errorMessage = 'Error de autenticación: ${response.statusCode}';
          }
        }

        throw Exception(errorMessage);
      }
    } on Exception {
      rethrow;
    } catch (e) {
      throw Exception('Error al autenticar con el servidor: ${e.toString()}');
    }
  }

  Future<UserModel> _registerWithBackend({
    required String name,
    required String email,
    required String phone,
    required String role,
    required String firebaseUid,
    String? tenantId,
  }) async {
    // Primero verificar si el usuario ya existe para evitar peticiones innecesarias
    try {
      final existingUser = await getUserInfo();
      return existingUser;
    } catch (_) {
      // Si getUserInfo falla, el usuario no existe, continuar con el registro
    }

    // Solo hacer UN intento de registro para evitar rate limiting
    // Si falla, mejor mostrar un error claro que hacer múltiples reintentos
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
          if (tenantId != null) 'tenantId': tenantId,
        }),
      );

      if (response.statusCode == 201) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else if (response.statusCode == 429) {
        // Rate limiting - no reintentar, mostrar mensaje claro
        throw Exception(
          'El servidor está recibiendo demasiadas peticiones. Por favor, espera unos minutos e intenta nuevamente.',
        );
      } else if (response.statusCode == 409) {
        // User already exists - obtener información del usuario existente
        try {
          return await getUserInfo();
        } catch (e) {
          throw Exception(
            'El usuario ya existe pero no se pudo obtener su información. Por favor, intenta iniciar sesión.',
          );
        }
      } else {
        final errorBody = response.body;
        String errorMessage =
            'Error al registrar usuario: ${response.statusCode}';
        try {
          final errorData = json.decode(errorBody);
          errorMessage =
              errorData['error'] ?? errorData['details'] ?? errorMessage;
        } catch (_) {
          // Use default error message
        }
        throw Exception(errorMessage);
      }
    } catch (e) {
      // Si es nuestro Exception personalizado, re-lanzarlo
      if (e is Exception) {
        rethrow;
      }
      throw Exception('Error al registrar usuario: ${e.toString()}');
    }
  }

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

  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } catch (e) {
      rethrow;
    }
  }

  bool get isEmailVerified => currentFirebaseUser?.emailVerified ?? false;

  String? get currentUserEmail => currentFirebaseUser?.email;

  String? get currentUserName => currentFirebaseUser?.displayName;
}

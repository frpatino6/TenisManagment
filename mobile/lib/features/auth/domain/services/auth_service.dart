import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/config/app_config.dart';
import '../../../../core/constants/timeouts.dart';
import '../../../../core/exceptions/exceptions.dart';
import '../../../../core/logging/logger.dart';
import '../models/user_model.dart';

/// Service responsible for user authentication operations
/// Handles Firebase Auth, Google Sign-In, and backend API communication
/// Manages user session state and authentication flows
class AuthService {
  String get _baseUrl => AppConfig.authBaseUrl;

  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final _logger = AppLogger.tag('AuthService');
  final http.Client _httpClient;

  AuthService({
    FirebaseAuth? firebaseAuth,
    GoogleSignIn? googleSignIn,
    http.Client? httpClient,
  })  : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn(),
        _httpClient = httpClient ?? http.Client();

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  User? get currentFirebaseUser => _firebaseAuth.currentUser;

  bool get isAuthenticated => currentFirebaseUser != null;

  /// Initiates Google Sign-In authentication flow
  /// Returns [UserModel] with user data from backend
  /// Throws [Exception] if authentication fails or is cancelled
  Future<UserModel> signInWithGoogle() async {
    _logger.info('Iniciando autenticación con Google');
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
          throw AuthException(
            'Inicio de sesión con Google cancelado',
            code: 'GOOGLE_SIGN_IN_CANCELLED',
          );
        }

        final GoogleSignInAuthentication googleAuth =
            await googleUser.authentication;

        if (googleAuth.idToken == null) {
          throw AuthException(
            'No se pudo obtener el token de Google',
            code: 'GOOGLE_TOKEN_ERROR',
          );
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
        throw AuthException(
          'No se pudo iniciar sesión con Google',
          code: 'GOOGLE_SIGN_IN_FAILED',
        );
      }

      final UserModel userModel = await _authenticateWithBackend(user);
      _logger.info('Autenticación con Google exitosa', {'userId': user.uid});
      return userModel;
    } on AppException catch (e, stackTrace) {
      _logger.error(
        'Error en autenticación con Google',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    } catch (e, stackTrace) {
      _logger.error(
        'Error inesperado en autenticación con Google',
        error: e,
        stackTrace: stackTrace,
      );
      rethrow;
    }
  }

  Future<UserModel> signInWithEmail(String email, String password) async {
    _logger.info('Iniciando autenticación con email', {'email': email});
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
            throw AuthException.invalidCredentials(
              message:
                  'La contraseña es incorrecta. Si te registraste con Google, usa "Continuar con Google". Si olvidaste tu contraseña, revisa tu email para restablecerla.',
            );
          } catch (resetError) {
            // Si el error es nuestra excepción personalizada, re-lanzarlo
            if (resetError is AuthException) {
              rethrow;
            }
            // Si falla el envío de recuperación, el usuario probablemente no existe
            throw AuthException.userNotFound();
          }
        }
        rethrow; // Re-lanzar otros errores
      }

      final User? user = userCredential.user;
      if (user == null) {
        throw AuthException(
          'No se pudo obtener el usuario después del login',
          code: 'USER_RETRIEVAL_FAILED',
        );
      }

      try {
        final UserModel userModel = await _authenticateWithBackend(user);
        _logger.info('Autenticación con email exitosa', {'userId': user.uid});
        return userModel;
      } catch (backendError) {
        _logger.error('Error al autenticar con backend', error: backendError);
        rethrow;
      }
    } on FirebaseAuthException catch (e) {
      _logger.warning('Error de Firebase Auth', {
        'code': e.code,
        'message': e.message,
      });
      switch (e.code) {
        case 'wrong-password':
          throw AuthException.invalidCredentials();
        case 'user-not-found':
          throw AuthException.userNotFound();
        case 'invalid-email':
          throw ValidationException.invalidField(
            field: 'email',
            reason: 'El formato del email es inválido',
          );
        case 'user-disabled':
          throw AuthException(
            'Esta cuenta ha sido deshabilitada',
            code: 'USER_DISABLED',
          );
        case 'too-many-requests':
          throw AuthException(
            'Demasiados intentos fallidos. Intenta más tarde',
            code: 'TOO_MANY_REQUESTS',
          );
        case 'operation-not-allowed':
          throw AuthException(
            'El método de autenticación no está habilitado',
            code: 'OPERATION_NOT_ALLOWED',
          );
        case 'network-request-failed':
          throw NetworkException.noConnection();
        case 'invalid-credential':
          throw AuthException.invalidCredentials(
            message:
                'Email o contraseña incorrectos. Si te registraste con Google, usa "Continuar con Google" para iniciar sesión.',
          );
        default:
          throw AuthException(
            'Error de autenticación: ${e.message ?? e.code}',
            code: e.code,
          );
      }
    } on AppException {
      rethrow;
    } catch (e) {
      final errorStr = e.toString();
      if (errorStr.contains('credential') ||
          errorStr.contains('incorrect') ||
          errorStr.contains('expired')) {
        throw AuthException.invalidCredentials(
          message:
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
              throw AuthException.emailAlreadyExists(
                message:
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
              throw AuthException.emailAlreadyExists(
                message:
                    'Este email ya está registrado pero la contraseña es incorrecta. Por favor, usa la pantalla de inicio de sesión o recupera tu contraseña.',
              );
            }
            rethrow;
          }
        } else {
          switch (e.code) {
            case 'weak-password':
              throw ValidationException.invalidField(
                field: 'password',
                reason:
                    'La contraseña es muy débil. Debe tener al menos 6 caracteres',
              );
            case 'invalid-email':
              throw ValidationException.invalidField(
                field: 'email',
                reason: 'El formato del email es inválido',
              );
            case 'operation-not-allowed':
              throw AuthException(
                'El registro con email no está habilitado en Firebase',
                code: 'OPERATION_NOT_ALLOWED',
              );
            case 'network-request-failed':
              throw NetworkException.noConnection();
            default:
              throw AuthException(
                'Error al registrar: ${e.message ?? e.code}',
                code: e.code,
              );
          }
        }
      }

      if (user == null) {
        throw AuthException(
          'No se pudo registrar o iniciar sesión con Firebase',
          code: 'FIREBASE_REGISTRATION_FAILED',
        );
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
        throw AuthException.notAuthenticated();
      }

      final idToken = await user.getIdToken(true) ?? '';
      if (idToken.isEmpty) {
        throw AuthException.tokenExpired(
          message: 'No se pudo obtener el token de Firebase',
        );
      }

      final response = await _httpClient
          .get(
            Uri.parse('$_baseUrl/firebase/me'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $idToken',
            },
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout(
                message: 'Timeout al obtener información del usuario',
              );
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        return UserModel.fromJson(data);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw AuthException.tokenExpired();
      } else if (response.statusCode == 404) {
        throw AuthException.userNotFound();
      } else {
        throw NetworkException.serverError(
          message: 'Error al obtener información del usuario',
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel> _authenticateWithBackend(User user) async {
    _logger.debug('Autenticando con backend', {'userId': user.uid});
    try {
      // Esperar un momento para asegurar que el token esté listo
      await Future.delayed(Timeouts.firebaseTokenDelay);

      String idToken;
      try {
        idToken = await user.getIdToken(true) ?? ''; // Force refresh
      } catch (tokenError) {
        // Intentar sin forzar refresh
        idToken = await user.getIdToken() ?? '';
      }

      if (idToken.isEmpty) {
        throw AuthException.tokenExpired(
          message:
              'No se pudo obtener el token de Firebase. Por favor, intenta iniciar sesión nuevamente.',
        );
      }

      final url = Uri.parse('$_baseUrl/firebase/verify');

      final response = await _httpClient
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'idToken': idToken}),
          )
          .timeout(
            Timeouts.httpRequest,
            onTimeout: () {
              throw NetworkException.timeout(
                message: 'Timeout al conectar con el servidor',
              );
            },
          );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        _logger.debug('Autenticación con backend exitosa');
        return UserModel.fromJson(data['user'] as Map<String, dynamic>);
      } else {
        _logger.warning('Error en respuesta del backend', {
          'statusCode': response.statusCode,
        });
        final errorBody = response.body;

        String errorMessage;
        try {
          final errorData = json.decode(errorBody) as Map<String, dynamic>;
          errorMessage =
              errorData['error'] as String? ??
              errorData['details'] as String? ??
              'Error de autenticación en el servidor';
        } catch (_) {
          // Si no se puede parsear el JSON, usar el mensaje por defecto según el código
          if (response.statusCode == 401) {
            throw AuthException.tokenExpired();
          } else if (response.statusCode == 404) {
            throw AuthException.userNotFound();
          } else if (response.statusCode == 503) {
            throw NetworkException.serverError(
              message:
                  'Firebase está deshabilitado en el servidor. Contacta al administrador.',
              statusCode: response.statusCode,
            );
          } else {
            errorMessage = 'Error de autenticación: ${response.statusCode}';
          }
        }

        if (response.statusCode == 401) {
          throw AuthException.tokenExpired();
        } else if (response.statusCode == 404) {
          throw AuthException.userNotFound();
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(
        message: 'Error al autenticar con el servidor: ${e.toString()}',
      );
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
      final response = await _httpClient.post(
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
        throw NetworkException.serverError(
          message:
              'El servidor está recibiendo demasiadas peticiones. Por favor, espera unos minutos e intenta nuevamente.',
          statusCode: response.statusCode,
        );
      } else if (response.statusCode == 409) {
        // User already exists - obtener información del usuario existente
        try {
          return await getUserInfo();
        } catch (e) {
          throw AuthException.emailAlreadyExists(
            message:
                'El usuario ya existe pero no se pudo obtener su información. Por favor, intenta iniciar sesión.',
          );
        }
      } else {
        final errorBody = response.body;
        String errorMessage =
            'Error al registrar usuario: ${response.statusCode}';
        try {
          final errorData = json.decode(errorBody) as Map<String, dynamic>;
          errorMessage =
              errorData['error'] as String? ??
              errorData['details'] as String? ??
              errorMessage;
        } catch (_) {
          // Use default error message
        }

        if (response.statusCode == 400 || response.statusCode == 422) {
          throw ValidationException(errorMessage, code: 'VALIDATION_ERROR');
        } else {
          throw NetworkException.serverError(
            message: errorMessage,
            statusCode: response.statusCode,
          );
        }
      }
    } on AppException {
      rethrow;
    } catch (e) {
      throw NetworkException.serverError(
        message: 'Error al registrar usuario: ${e.toString()}',
      );
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

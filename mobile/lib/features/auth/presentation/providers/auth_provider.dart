import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../domain/models/user_model.dart';
import '../../domain/services/auth_service.dart';


final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});


final firebaseAuthProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});


final authStateProvider = StreamProvider<UserModel?>((ref) {
  final authService = ref.watch(authServiceProvider);
  final firebaseUser = ref.watch(firebaseAuthProvider);

  return firebaseUser.when(
    data: (user) async* {
      if (user != null) {
        try {
          final userModel = await authService.getUserInfo();
          yield userModel;
        } catch (e) {
          yield null;
        }
      } else {
        yield null;
      }
    },
    loading: () async* {
      yield null;
    },
    error: (error, stackTrace) async* {
      yield null;
    },
  );
});


class AuthLoadingNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setLoading(bool loading) {
    state = loading;
  }
}


class AuthErrorNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void setError(String? error) {
    state = error;
  }

  void clearError() {
    state = null;
  }
}


final authLoadingProvider = NotifierProvider<AuthLoadingNotifier, bool>(
  () => AuthLoadingNotifier(),
);


final authErrorProvider = NotifierProvider<AuthErrorNotifier, String?>(
  () => AuthErrorNotifier(),
);


class AuthNotifier extends Notifier<AsyncValue<UserModel?>> {
  @override
  AsyncValue<UserModel?> build() {
    _initialize();
    return const AsyncValue.loading();
  }

  void _initialize() {
    ref.listen(firebaseAuthProvider, (previous, next) {
      next.when(
        data: (user) async {
          if (user != null) {
            try {
              final authService = ref.read(authServiceProvider);
              final userModel = await authService.getUserInfo();
              state = AsyncValue.data(userModel);
            } catch (e) {
              state = AsyncValue.error(e, StackTrace.current);
            }
          } else {
            state = const AsyncValue.data(null);
          }
        },
        loading: () {
          state = const AsyncValue.loading();
        },
        error: (error, stackTrace) {
          state = AsyncValue.error(error, stackTrace);
        },
      );
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    try {
      ref.read(authLoadingProvider.notifier).setLoading(true);
      ref.read(authErrorProvider.notifier).setError(null);

      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmail(email, password);
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError(e.toString());
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      ref.read(authLoadingProvider.notifier).setLoading(true);
      ref.read(authErrorProvider.notifier).setError(null);

      final authService = ref.read(authServiceProvider);
      await authService.signInWithGoogle();
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError(e.toString());
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required String phone,
    required String role,
  }) async {
    try {
      ref.read(authLoadingProvider.notifier).setLoading(true);
      ref.read(authErrorProvider.notifier).setError(null);

      final authService = ref.read(authServiceProvider);
      await authService.registerWithEmail(
        name: name,
        email: email,
        password: password,
        phone: phone,
        role: role,
      );
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError(e.toString());
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  Future<void> signOut() async {
    try {
      ref.read(authLoadingProvider.notifier).setLoading(true);
      ref.read(authErrorProvider.notifier).setError(null);

      final authService = ref.read(authServiceProvider);
      await authService.signOut();
    } catch (e) {
      ref.read(authErrorProvider.notifier).setError(e.toString());
      rethrow;
    } finally {
      ref.read(authLoadingProvider.notifier).setLoading(false);
    }
  }

  void clearError() {
    ref.read(authErrorProvider.notifier).clearError();
  }
}


final authNotifierProvider =
    NotifierProvider<AuthNotifier, AsyncValue<UserModel?>>(() {
      return AuthNotifier();
    });


final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user != null,
    loading: () => false,
    error: (error, stackTrace) => false,
  );
});


final currentUserProvider = Provider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) => user,
    loading: () => null,
    error: (error, stackTrace) => null,
  );
});

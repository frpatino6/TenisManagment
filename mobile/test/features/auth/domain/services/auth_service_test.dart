import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:tennis_management/features/auth/domain/services/auth_service.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';
import 'package:tennis_management/features/auth/domain/models/user_model.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockUserCredential extends Mock implements UserCredential {}

class MockGoogleSignIn extends Mock implements GoogleSignIn {}

class MockGoogleSignInAccount extends Mock implements GoogleSignInAccount {}

class MockGoogleSignInAuthentication extends Mock
    implements GoogleSignInAuthentication {}

class MockHttpClient extends Mock implements http.Client {}

class MockStream extends Mock implements Stream<User?> {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('AuthService', () {
    late AuthService authService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockGoogleSignIn mockGoogleSignIn;
    late MockHttpClient mockHttpClient;
    late MockUser mockUser;
    late MockUserCredential mockUserCredential;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockGoogleSignIn = MockGoogleSignIn();
      mockHttpClient = MockHttpClient();
      mockUser = MockUser();
      mockUserCredential = MockUserCredential();

      authService = AuthService(
        firebaseAuth: mockFirebaseAuth,
        googleSignIn: mockGoogleSignIn,
        httpClient: mockHttpClient,
      );
    });

    group('isAuthenticated', () {
      test('should return true when user is authenticated', () {
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        expect(authService.isAuthenticated, isTrue);
      });

      test('should return false when no user is authenticated', () {
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        expect(authService.isAuthenticated, isFalse);
      });
    });

    group('currentFirebaseUser', () {
      test('should return current user when authenticated', () {
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);

        expect(authService.currentFirebaseUser, equals(mockUser));
      });

      test('should return null when not authenticated', () {
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        expect(authService.currentFirebaseUser, isNull);
      });
    });

    group('authStateChanges', () {
      test('should return auth state changes stream', () {
        final mockStream = MockStream();
        when(
          () => mockFirebaseAuth.authStateChanges(),
        ).thenAnswer((_) => mockStream);

        expect(authService.authStateChanges, equals(mockStream));
      });
    });

    group('signOut', () {
      test('should sign out from Firebase and Google Sign-In', () async {
        when(() => mockFirebaseAuth.signOut()).thenAnswer((_) async => {});
        when(() => mockGoogleSignIn.signOut()).thenAnswer((_) async => null);

        await authService.signOut();

        verify(() => mockFirebaseAuth.signOut()).called(1);
        verify(() => mockGoogleSignIn.signOut()).called(1);
      });

      test('should handle errors during sign out', () async {
        when(
          () => mockFirebaseAuth.signOut(),
        ).thenThrow(Exception('Sign out failed'));

        expect(() => authService.signOut(), throwsException);
      });
    });

    group('getUserInfo', () {
      test('should return UserModel when request succeeds', () async {
        const idToken = 'test-token';
        final userJson = {
          'id': 'user-123',
          'email': 'test@example.com',
          'name': 'Test User',
          'role': 'professor',
        };
        final response = http.Response(json.encode(userJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        final result = await authService.getUserInfo();

        expect(result, isA<UserModel>());
        expect(result.id, equals('user-123'));
        expect(result.email, equals('test@example.com'));
        expect(result.name, equals('Test User'));
        expect(result.role, equals('professor'));
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => authService.getUserInfo(),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test(
        'should throw AuthException.tokenExpired when token is empty',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
          when(() => mockUser.getIdToken(true)).thenAnswer((_) async => '');

          expect(
            () => authService.getUserInfo(),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test('should throw AuthException.tokenExpired on 401/403', () async {
        const idToken = 'test-token';
        final response = http.Response('Unauthorized', 401);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        expect(() => authService.getUserInfo(), throwsA(isA<AuthException>()));
      });

      test('should throw AuthException.userNotFound on 404', () async {
        const idToken = 'test-token';
        final response = http.Response('Not Found', 404);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        expect(() => authService.getUserInfo(), throwsA(isA<AuthException>()));
      });

      test(
        'should throw NetworkException.serverError on other status codes',
        () async {
          const idToken = 'test-token';
          final response = http.Response('Server Error', 500);

          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
          when(
            () => mockUser.getIdToken(true),
          ).thenAnswer((_) async => idToken);
          when(
            () => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            ),
          ).thenAnswer((_) async => response);

          expect(
            () => authService.getUserInfo(),
            throwsA(isA<NetworkException>()),
          );
        },
      );
    });

    group('signInWithEmail', () {
      test(
        'should throw AuthException when user is null after sign in',
        () async {
          when(
            () => mockFirebaseAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenAnswer((_) async => mockUserCredential);
          when(() => mockUserCredential.user).thenReturn(null);

          expect(
            () => authService.signInWithEmail('test@example.com', 'password'),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test(
        'should throw AuthException.invalidCredentials on wrong-password',
        () async {
          when(
            () => mockFirebaseAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(FirebaseAuthException(code: 'wrong-password'));

          expect(
            () => authService.signInWithEmail('test@example.com', 'wrong'),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test(
        'should throw AuthException.userNotFound on user-not-found',
        () async {
          when(
            () => mockFirebaseAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(FirebaseAuthException(code: 'user-not-found'));

          expect(
            () => authService.signInWithEmail('test@example.com', 'password'),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test('should throw ValidationException on invalid-email', () async {
        when(
          () => mockFirebaseAuth.signInWithEmailAndPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenThrow(FirebaseAuthException(code: 'invalid-email'));

        expect(
          () => authService.signInWithEmail('invalid-email', 'password'),
          throwsA(isA<ValidationException>()),
        );
      });

      test(
        'should throw NetworkException.noConnection on network-request-failed',
        () async {
          when(
            () => mockFirebaseAuth.signInWithEmailAndPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            ),
          ).thenThrow(FirebaseAuthException(code: 'network-request-failed'));

          expect(
            () => authService.signInWithEmail('test@example.com', 'password'),
            throwsA(isA<NetworkException>()),
          );
        },
      );
    });

    // Note: signInWithGoogle and registerWithEmail tests are more complex
    // and require extensive mocking of Google Sign-In and Firebase Auth flows.
    // These are better suited for integration tests or widget tests.
    // The structure above demonstrates how to test the service with mocks.
  });
}

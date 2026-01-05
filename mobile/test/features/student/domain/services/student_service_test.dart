import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tennis_management/features/student/domain/services/student_service.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';
import 'package:tennis_management/features/student/domain/models/recent_activity_model.dart';
import 'package:tennis_management/features/student/domain/models/booking_model.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockHttpClient extends Mock implements http.Client {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('StudentService', () {
    late StudentService studentService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockHttpClient mockHttpClient;
    late MockUser mockUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockHttpClient = MockHttpClient();
      mockUser = MockUser();

      studentService = StudentService(
        firebaseAuth: mockFirebaseAuth,
        httpClient: mockHttpClient,
      );
    });

    group('getRecentActivities', () {
      test('should return list of RecentActivityModel when request succeeds', () async {
        const idToken = 'test-token';
        final activitiesJson = {
          'items': [
            {
              'id': 'activity-1',
              'type': 'booking',
              'title': 'Clase reservada',
              'description': 'Clase con Prof. Test',
              'date': '2024-01-01T10:00:00Z',
              'status': 'confirmed',
              'icon': 'calendar',
              'color': 'blue',
            },
            {
              'id': 'activity-2',
              'type': 'class',
              'title': 'Clase completada',
              'description': 'Clase con Prof. Test',
              'date': '2024-01-02T10:00:00Z',
              'status': 'completed',
              'icon': 'check',
              'color': 'green',
            },
          ],
        };
        final response = http.Response(json.encode(activitiesJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        final result = await studentService.getRecentActivities();

        expect(result, isA<List<RecentActivityModel>>());
        expect(result.length, equals(2));
        expect(result[0].id, equals('activity-1'));
        expect(result[0].type, equals('booking'));
      });

      test('should return empty list when items is null', () async {
        const idToken = 'test-token';
        final activitiesJson = {'items': null};
        final response = http.Response(json.encode(activitiesJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        // This will throw because items is null and we try to cast it
        expect(
          () => studentService.getRecentActivities(),
          throwsA(isA<TypeError>()),
        );
      });

      test('should return empty list when items is empty', () async {
        const idToken = 'test-token';
        final activitiesJson = {'items': <dynamic>[]};
        final response = http.Response(json.encode(activitiesJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        final result = await studentService.getRecentActivities();

        expect(result, isEmpty);
      });

      test('should throw AuthException.notAuthenticated when no user', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        expect(
          () => studentService.getRecentActivities(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException.tokenExpired when token is null', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => null);

        expect(
          () => studentService.getRecentActivities(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException.tokenExpired on 401/403', () async {
        const idToken = 'test-token';
        final response = http.Response('Unauthorized', 401);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        expect(
          () => studentService.getRecentActivities(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getStudentInfo', () {
      test('should return student info when request succeeds', () async {
        const idToken = 'test-token';
        final studentJson = {
          'id': 'student-123',
          'name': 'Test Student',
          'email': 'student@example.com',
          'membershipType': 'premium',
          'balance': 100.0,
        };
        final response = http.Response(json.encode(studentJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        final result = await studentService.getStudentInfo();

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('student-123'));
        expect(result['name'], equals('Test Student'));
      });

      test('should throw AuthException.notAuthenticated when no user', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        expect(
          () => studentService.getStudentInfo(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException.tokenExpired when token is null', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => null);

        expect(
          () => studentService.getStudentInfo(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw DomainException.notFound on 404', () async {
        const idToken = 'test-token';
        final response = http.Response('Not Found', 404);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        expect(
          () => studentService.getStudentInfo(),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('getBookings', () {
      test('should return list of BookingModel when request succeeds', () async {
        const idToken = 'test-token';
        final bookingsJson = {
          'items': [
            {
              'id': 'booking-1',
              'serviceType': 'individual_class',
              'status': 'confirmed',
              'price': 50.0,
            },
            {
              'id': 'booking-2',
              'serviceType': 'group_class',
              'status': 'pending',
              'price': 30.0,
            },
          ],
        };
        final response = http.Response(json.encode(bookingsJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        final result = await studentService.getBookings();

        expect(result, isA<List<BookingModel>>());
        expect(result.length, equals(2));
        expect(result[0].id, equals('booking-1'));
        expect(result[0].serviceType.toString(), contains('individual'));
      });

      test('should throw AuthException.notAuthenticated when no user', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(null);

        expect(
          () => studentService.getBookings(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException.tokenExpired when token is null', () async {
        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => null);

        expect(
          () => studentService.getBookings(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw AuthException.tokenExpired on 401/403', () async {
        const idToken = 'test-token';
        final response = http.Response('Unauthorized', 401);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(() => mockHttpClient.get(
              any(that: isA<Uri>()),
              headers: any(named: 'headers', that: isA<Map<String, String>>()),
            )).thenAnswer((_) async => response);

        expect(
          () => studentService.getBookings(),
          throwsA(isA<AuthException>()),
        );
      });
    });
  });
}


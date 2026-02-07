import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tennis_management/features/booking/domain/services/booking_service.dart';
import 'package:tennis_management/core/services/http_client.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';
import 'package:tennis_management/features/booking/domain/models/professor_model.dart';
import 'package:tennis_management/features/booking/domain/models/available_schedule_model.dart';

// Mocks
class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockAppHttpClient extends Mock implements AppHttpClient {}

void main() {
  setUpAll(() {
    // Register fallback values for mocktail
    registerFallbackValue(Uri.parse('https://example.com'));
    registerFallbackValue(<String, String>{});
  });

  group('BookingService', () {
    late BookingService bookingService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockAppHttpClient mockHttpClient;
    late MockUser mockUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockHttpClient = MockAppHttpClient();
      mockUser = MockUser();

      bookingService = BookingService(
        mockHttpClient,
        firebaseAuth: mockFirebaseAuth,
      );
    });

    group('getProfessors', () {
      test(
        'should return list of ProfessorBookingModel when request succeeds',
        () async {
          const idToken = 'test-token';
          final professorsJson = {
            'items': [
              {
                'id': 'prof-1',
                'name': 'Professor One',
                'email': 'prof1@example.com',
                'specialties': ['Tenis', 'Padel'],
                'pricing': {
                  'individualClass': 50.0,
                  'groupClass': 30.0,
                  'courtRental': 25.0,
                },
              },
              {
                'id': 'prof-2',
                'name': 'Professor Two',
                'email': 'prof2@example.com',
                'specialties': ['Tenis'],
                'pricing': {
                  'individualClass': 60.0,
                  'groupClass': 35.0,
                  'courtRental': 30.0,
                },
              },
            ],
          };
          final response = http.Response(json.encode(professorsJson), 200);

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

          final result = await bookingService.getProfessors();

          expect(result, isA<List<ProfessorBookingModel>>());
          expect(result.length, equals(2));
          expect(result[0].id, equals('prof-1'));
          expect(result[0].name, equals('Professor One'));
        },
      );

      test('should return empty list when items is empty', () async {
        const idToken = 'test-token';
        final professorsJson = {'items': <dynamic>[]};
        final response = http.Response(json.encode(professorsJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        final result = await bookingService.getProfessors();

        expect(result, isEmpty);
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => bookingService.getProfessors(),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test(
        'should throw AuthException.tokenExpired when token is null',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
          when(() => mockUser.getIdToken(true)).thenAnswer((_) async => null);

          expect(
            () => bookingService.getProfessors(),
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

        expect(
          () => bookingService.getProfessors(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('getAvailableSchedules', () {
      test(
        'should return list of AvailableScheduleModel when request succeeds',
        () async {
          const idToken = 'test-token';
          const professorId = 'prof-1';
          final schedulesJson = {
            'items': [
              {
                'id': 'schedule-1',
                'professorId': professorId,
                'date': '2024-01-01T10:00:00Z',
                'startTime': '2024-01-01T10:00:00Z',
                'endTime': '2024-01-01T11:00:00Z',
                'status': 'available',
              },
              {
                'id': 'schedule-2',
                'professorId': professorId,
                'date': '2024-01-01T11:00:00Z',
                'startTime': '2024-01-01T11:00:00Z',
                'endTime': '2024-01-01T12:00:00Z',
                'status': 'available',
              },
            ],
          };
          final response = http.Response(json.encode(schedulesJson), 200);

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

          final result = await bookingService.getAvailableSchedules(
            professorId,
          );

          expect(result, isA<List<AvailableScheduleModel>>());
          expect(result.length, equals(2));
          expect(result[0].id, equals('schedule-1'));
        },
      );

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => bookingService.getAvailableSchedules('prof-1'),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test('should throw DomainException.notFound on 404', () async {
        const idToken = 'test-token';
        const professorId = 'prof-1';
        final response = http.Response('Not Found', 404);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        expect(
          () => bookingService.getAvailableSchedules(professorId),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('bookLesson', () {
      test('should return booking data when request succeeds', () async {
        const idToken = 'test-token';
        const scheduleId = 'schedule-1';
        final bookingJson = {
          'id': 'booking-123',
          'scheduleId': scheduleId,
          'serviceType': 'individual_class',
          'status': 'confirmed',
        };
        final response = http.Response(json.encode(bookingJson), 201);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.post(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => response);

        final result = await bookingService.bookLesson(
          scheduleId,
          serviceType: 'individual_class',
          price: 50.0,
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('booking-123'));
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => bookingService.bookLesson(
              'schedule-1',
              serviceType: 'individual_class',
              price: 50.0,
            ),
            throwsA(isA<AuthException>()),
          );
        },
      );

      test('should throw ValidationException on 400/422', () async {
        const idToken = 'test-token';
        const scheduleId = 'schedule-1';
        final errorJson = {'error': 'Invalid service type'};
        final response = http.Response(json.encode(errorJson), 400);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.post(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => response);

        expect(
          () => bookingService.bookLesson(
            scheduleId,
            serviceType: 'invalid_type',
            price: 50.0,
          ),
          throwsA(isA<ValidationException>()),
        );
      });

      test('should throw ScheduleException.notFound on 404', () async {
        const idToken = 'test-token';
        const scheduleId = 'schedule-1';
        final errorJson = {'error': 'Schedule not found'};
        final response = http.Response(json.encode(errorJson), 404);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.post(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => response);

        expect(
          () => bookingService.bookLesson(
            scheduleId,
            serviceType: 'individual_class',
            price: 50.0,
          ),
          throwsA(isA<ScheduleException>()),
        );
      });

      test('should throw ScheduleException.conflict on 409', () async {
        const idToken = 'test-token';
        const scheduleId = 'schedule-1';
        final errorJson = {'error': 'Schedule already booked'};
        final response = http.Response(json.encode(errorJson), 409);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.post(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => response);

        expect(
          () => bookingService.bookLesson(
            scheduleId,
            serviceType: 'individual_class',
            price: 50.0,
          ),
          throwsA(isA<ScheduleException>()),
        );
      });
    });
  });
}

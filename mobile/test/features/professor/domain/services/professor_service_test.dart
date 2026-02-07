import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tennis_management/features/professor/domain/services/professor_service.dart';
import 'package:tennis_management/core/exceptions/exceptions.dart';
import 'package:tennis_management/features/professor/domain/models/professor_model.dart';
import 'package:tennis_management/features/professor/domain/models/student_summary_model.dart';
import 'package:tennis_management/features/professor/domain/models/professor_schedule_model.dart';

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

  group('ProfessorService', () {
    late ProfessorService professorService;
    late MockFirebaseAuth mockFirebaseAuth;
    late MockHttpClient mockHttpClient;
    late MockUser mockUser;

    setUp(() {
      mockFirebaseAuth = MockFirebaseAuth();
      mockHttpClient = MockHttpClient();
      mockUser = MockUser();

      professorService = ProfessorService(
        firebaseAuth: mockFirebaseAuth,
        httpClient: mockHttpClient,
      );
    });

    group('getProfessorInfo', () {
      test('should return ProfessorModel when request succeeds', () async {
        const idToken = 'test-token';
        final professorJson = {
          'id': 'prof-123',
          'name': 'Test Professor',
          'email': 'prof@example.com',
          'hourlyRate': 50.0,
          'rating': 4.5,
        };
        final response = http.Response(json.encode(professorJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        final result = await professorService.getProfessorInfo();

        expect(result, isA<ProfessorModel>());
        expect(result.id, equals('prof-123'));
        expect(result.name, equals('Test Professor'));
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => professorService.getProfessorInfo(),
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
          () => professorService.getProfessorInfo(),
          throwsA(isA<AuthException>()),
        );
      });

      test('should throw DomainException.notFound on 404', () async {
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

        expect(
          () => professorService.getProfessorInfo(),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('getStudents', () {
      test(
        'should return list of StudentSummaryModel when request succeeds',
        () async {
          const idToken = 'test-token';
          final studentsJson = {
            'items': [
              {
                'id': 'student-1',
                'name': 'Student One',
                'email': 'student1@example.com',
              },
              {
                'id': 'student-2',
                'name': 'Student Two',
                'email': 'student2@example.com',
              },
            ],
          };
          final response = http.Response(json.encode(studentsJson), 200);

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

          final result = await professorService.getStudents();

          expect(result, isA<List<StudentSummaryModel>>());
          expect(result.length, equals(2));
          expect(result[0].id, equals('student-1'));
        },
      );

      test('should return empty list when items is null', () async {
        const idToken = 'test-token';
        final studentsJson = <String, dynamic>{};
        final response = http.Response(json.encode(studentsJson), 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.get(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        final result = await professorService.getStudents();

        expect(result, isEmpty);
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => professorService.getStudents(),
            throwsA(isA<AuthException>()),
          );
        },
      );
    });

    group('getMySchedules', () {
      test(
        'should return list of ProfessorScheduleModel when request succeeds',
        () async {
          const idToken = 'test-token';
          final schedulesJson = {
            'items': [
              {
                'id': 'schedule-1',
                'date': '2024-01-01T10:00:00Z',
                'startTime': '2024-01-01T10:00:00Z',
                'endTime': '2024-01-01T11:00:00Z',
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

          final result = await professorService.getMySchedules();

          expect(result, isA<List<ProfessorScheduleModel>>());
          expect(result.length, equals(1));
          expect(result[0].id, equals('schedule-1'));
        },
      );

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => professorService.getMySchedules(),
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
          () => professorService.getMySchedules(),
          throwsA(isA<AuthException>()),
        );
      });
    });

    group('createSchedule', () {
      test('should return schedule data when request succeeds', () async {
        const idToken = 'test-token';
        final scheduleJson = {
          'id': 'new-schedule-1',
          'date': '2024-01-01T10:00:00Z',
          'startTime': '2024-01-01T10:00:00Z',
          'endTime': '2024-01-01T11:00:00Z',
        };
        final response = http.Response(json.encode(scheduleJson), 201);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.post(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
            body: any(named: 'body'),
          ),
        ).thenAnswer((_) async => response);

        final result = await professorService.createSchedule(
          date: DateTime(2024, 1, 1),
          startTime: DateTime(2024, 1, 1, 10),
          endTime: DateTime(2024, 1, 1, 11),
        );

        expect(result, isA<Map<String, dynamic>>());
        expect(result['id'], equals('new-schedule-1'));
      });

      test('should throw ScheduleException.conflict on 409', () async {
        const idToken = 'test-token';
        final errorJson = {
          'error': 'CONFLICT_SAME_TIME',
          'message': 'Schedule conflict',
          'conflictingTenantId': 'tenant-1',
        };
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
          () => professorService.createSchedule(
            date: DateTime(2024, 1, 1),
            startTime: DateTime(2024, 1, 1, 10),
            endTime: DateTime(2024, 1, 1, 11),
          ),
          throwsA(isA<ScheduleException>()),
        );
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => professorService.createSchedule(
              date: DateTime(2024, 1, 1),
              startTime: DateTime(2024, 1, 1, 10),
              endTime: DateTime(2024, 1, 1, 11),
            ),
            throwsA(isA<AuthException>()),
          );
        },
      );
    });

    group('deleteSchedule', () {
      test('should complete successfully when request succeeds', () async {
        const idToken = 'test-token';
        const scheduleId = 'schedule-1';
        final response = http.Response('', 200);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.delete(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        await professorService.deleteSchedule(scheduleId);

        verify(
          () => mockHttpClient.delete(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).called(1);
      });

      test('should throw ScheduleException.notFound on 404', () async {
        const idToken = 'test-token';
        const scheduleId = 'schedule-1';
        final errorJson = {'error': 'Schedule not found'};
        final response = http.Response(json.encode(errorJson), 404);

        when(() => mockFirebaseAuth.currentUser).thenReturn(mockUser);
        when(() => mockUser.getIdToken(true)).thenAnswer((_) async => idToken);
        when(
          () => mockHttpClient.delete(
            any(that: isA<Uri>()),
            headers: any(named: 'headers', that: isA<Map<String, String>>()),
          ),
        ).thenAnswer((_) async => response);

        expect(
          () => professorService.deleteSchedule(scheduleId),
          throwsA(isA<ScheduleException>()),
        );
      });

      test(
        'should throw AuthException.notAuthenticated when no user',
        () async {
          when(() => mockFirebaseAuth.currentUser).thenReturn(null);

          expect(
            () => professorService.deleteSchedule('schedule-1'),
            throwsA(isA<AuthException>()),
          );
        },
      );
    });
  });
}

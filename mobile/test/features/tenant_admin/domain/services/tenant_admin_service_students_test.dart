import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tennis_management/core/services/http_client.dart';
import 'package:tennis_management/features/tenant_admin/infrastructure/repositories/tenant_admin_repository_impl.dart';

class MockHttpClient extends Mock implements AppHttpClient {}

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

void main() {
  late TenantAdminRepositoryImpl repository;
  late MockHttpClient mockHttpClient;
  late MockFirebaseAuth mockAuth;
  late MockUser mockUser;

  setUp(() {
    mockHttpClient = MockHttpClient();
    mockAuth = MockFirebaseAuth();
    mockUser = MockUser();

    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(
      () => mockUser.getIdToken(any()),
    ).thenAnswer((_) async => 'fake-token');

    repository = TenantAdminRepositoryImpl(
      httpClient: mockHttpClient,
      auth: mockAuth,
    );

    registerFallbackValue(Uri());
  });

  group('TenantAdminRepositoryImpl - Students', () {
    test('getStudents should return pagination response', () async {
      final responseJson = {
        'students': [
          {
            'id': 's1',
            'name': 'John',
            'email': 'john@test.com',
            'membershipType': 'basic',
            'balance': 0.0,
            'isActive': true,
            'joinedAt': '2024-01-01T10:00:00Z',
          },
        ],
        'pagination': {'total': 1, 'page': 1, 'limit': 20, 'pages': 1},
      };

      when(
        () => mockHttpClient.get(
          any(),
          headers: any(named: 'headers'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseJson), 200));

      final result = await repository.getStudents();

      expect(result.students.length, 1);
      expect(result.students[0].name, 'John');
      expect(result.pagination.total, 1);
    });

    test('getStudentDetails should return detailed model', () async {
      final responseJson = {
        'id': 's1',
        'name': 'John',
        'email': 'john@test.com',
        'membershipType': 'basic',
        'balance': 50.0,
        'isActive': true,
        'joinedAt': '2024-01-01T10:00:00Z',
        'recentBookings': [],
      };

      when(
        () => mockHttpClient.get(
          any(),
          headers: any(named: 'headers'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseJson), 200));

      final result = await repository.getStudentDetails('s1');

      expect(result.name, 'John');
      expect(result.balance, 50.0);
    });

    test('updateStudentBalance should return new balance', () async {
      final responseJson = {
        'studentId': 's1',
        'newBalance': 150.0,
        'message': 'Success',
      };

      when(
        () => mockHttpClient.patch(
          any(),
          headers: any(named: 'headers'),
          body: any(named: 'body'),
          timeout: any(named: 'timeout'),
        ),
      ).thenAnswer((_) async => http.Response(json.encode(responseJson), 200));

      final result = await repository.updateStudentBalance(
        's1',
        amount: 50,
        type: 'add',
      );

      expect(result, 150.0);
    });
  });
}

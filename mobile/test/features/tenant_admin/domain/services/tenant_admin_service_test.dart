import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:tennis_management/features/tenant_admin/domain/services/tenant_admin_service.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/tenant_booking_model.dart';
import 'package:tennis_management/core/services/http_client.dart';

class MockFirebaseAuth extends Mock implements FirebaseAuth {}

class MockUser extends Mock implements User {}

class MockAppHttpClient extends Mock implements AppHttpClient {}

void main() {
  setUpAll(() {
    registerFallbackValue(Uri.parse('https://example.com'));
  });

  group('TenantAdminService', () {
    late TenantAdminService service;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockAppHttpClient mockHttpClient;

    setUp(() {
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockHttpClient = MockAppHttpClient();

      service = TenantAdminService(httpClient: mockHttpClient, auth: mockAuth);

      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(
        () => mockUser.getIdToken(any()),
      ).thenAnswer((_) async => 'fake-token');
    });

    test(
      'getBookingDetails should return a TenantBookingModel when successful',
      () async {
        final bookingJson = {
          'id': 'b1',
          'serviceType': 'court_rental',
          'status': 'confirmed',
          'price': 50.0,
          'createdAt': '2024-01-01T10:00:00.000Z',
          'updatedAt': '2024-01-01T10:00:00.000Z',
          'student': {
            'id': 's1',
            'name': 'Student 1',
            'email': 'student@test.com',
          },
        };

        when(
          () => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer((_) async => http.Response(jsonEncode(bookingJson), 200));

        final result = await service.getBookingDetails('b1');

        expect(result, isA<TenantBookingModel>());
        expect(result.id, 'b1');
        expect(result.student.name, 'Student 1');
      },
    );

    test(
      'getBookingDetails should throw exception when request fails',
      () async {
        when(
          () => mockHttpClient.get(
            any(),
            headers: any(named: 'headers'),
            timeout: any(named: 'timeout'),
          ),
        ).thenAnswer((_) async => http.Response('Not Found', 404));

        expect(() => service.getBookingDetails('b1'), throwsException);
      },
    );
  });
}

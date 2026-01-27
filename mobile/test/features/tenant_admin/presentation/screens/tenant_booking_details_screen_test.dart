import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:tennis_management/features/tenant_admin/presentation/screens/tenant_booking_details_screen.dart';
import 'package:tennis_management/features/tenant_admin/domain/services/tenant_admin_service.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/tenant_booking_model.dart';
import 'package:tennis_management/features/tenant_admin/presentation/providers/tenant_admin_provider.dart';

class MockTenantAdminService extends Mock implements TenantAdminService {}

void main() {
  late MockTenantAdminService mockService;

  setUp(() {
    mockService = MockTenantAdminService();
  });

  Widget createTestWidget(String bookingId) {
    return ProviderScope(
      overrides: [tenantAdminServiceProvider.overrideWithValue(mockService)],
      child: MaterialApp(
        home: TenantBookingDetailsScreen(bookingId: bookingId),
      ),
    );
  }

  group('TenantBookingDetailsScreen', () {
    testWidgets('should display booking details when successful', (
      tester,
    ) async {
      final booking = TenantBookingModel(
        id: 'b1',
        serviceType: 'court_rental',
        status: 'confirmed',
        paymentStatus: 'paid',
        price: 50.0,
        date: DateTime(2024, 1, 1),
        startTime: DateTime(2024, 1, 1, 10),
        endTime: DateTime(2024, 1, 1, 11),
        student: StudentInfo(
          id: 's1',
          name: 'John Doe',
          email: 'john@test.com',
        ),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      when(
        () => mockService.getBookingDetails('b1'),
      ).thenAnswer((_) async => booking);

      await tester.pumpWidget(createTestWidget('b1'));

      // Initially shows loading
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pumpAndSettle();

      // Verify details
      expect(find.text('Detalles de Reserva'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@test.com'), findsOneWidget);
      expect(find.text('Confirmada'), findsOneWidget);
      expect(find.text('\$50'), findsOneWidget);
    });

    testWidgets('should show error widget when request fails', (tester) async {
      when(
        () => mockService.getBookingDetails('b1'),
      ).thenAnswer((_) async => throw Exception('Failed to load'));

      await tester.pumpWidget(createTestWidget('b1'));
      await tester.pump(); // Start loading
      await tester.pumpAndSettle(); // Finish loading with error

      expect(find.textContaining('Failed to load'), findsOneWidget);
    });
  });
}

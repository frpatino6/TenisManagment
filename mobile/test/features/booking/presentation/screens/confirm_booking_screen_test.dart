import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/core/providers/tenant_provider.dart';
import 'package:tennis_management/features/booking/domain/models/schedule_model.dart';
import 'package:tennis_management/features/booking/presentation/providers/booking_provider.dart';
import 'package:tennis_management/features/booking/presentation/screens/confirm_booking_screen.dart';
import 'package:tennis_management/features/payment/presentation/widgets/payment_dialog.dart';
import 'package:tennis_management/features/student/presentation/providers/student_provider.dart';
import 'package:tennis_management/features/tenant/domain/models/tenant_model.dart';

void main() {
  group('ConfirmBookingScreen', () {
    testWidgets('stops syncing when payment fails', (
      WidgetTester tester,
    ) async {
      final schedule = ScheduleModel(
        id: 'schedule-1',
        startTime: DateTime.now().add(const Duration(days: 1)),
        endTime: DateTime.now().add(const Duration(days: 1, hours: 1)),
        status: 'available',
        isAvailable: true,
      );

      final testTenant = TenantModel(
        id: 'tenant-1',
        name: 'Test Center',
        slug: 'test-center',
        isActive: true,
        config: {
          'payments': {
            'wompi': {'pubKey': 'test-key'},
          },
        },
      );

      final container = ProviderContainer(
        overrides: [
          currentTenantProvider.overrideWith((ref) async => testTenant),
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 0,
              'totalSpent': 0,
              'totalClasses': 0,
              'totalPayments': 0,
            },
          ),
          myBookingsProvider.overrideWith((ref) async => []),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: ConfirmBookingScreen(
              schedule: schedule,
              professorId: 'prof-1',
              professorName: 'Profesor',
              tenantId: 'tenant-1',
              tenantName: 'Test Center',
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.ensureVisible(find.text('Recargar y Reservar'));
      await tester.tap(find.text('Recargar y Reservar'));
      await tester.pump();

      final dialog = tester.widget<PaymentDialog>(find.byType(PaymentDialog));
      dialog.onPaymentStart?.call();
      await tester.pump();

      expect(find.text('Procesando reserva...'), findsOneWidget);

      dialog.onPaymentFailed?.call();
      await tester.pump();

      expect(find.text('Procesando reserva...'), findsNothing);

      await tester.tap(
        find.descendant(
          of: find.byType(AlertDialog),
          matching: find.text('Cancelar'),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(Container());
      container.dispose();
    });
  });
}

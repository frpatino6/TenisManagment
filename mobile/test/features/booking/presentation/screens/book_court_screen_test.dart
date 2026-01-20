import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/core/config/app_config.dart';
import 'package:tennis_management/core/providers/tenant_provider.dart';
import 'package:tennis_management/features/booking/domain/models/booking_model.dart';
import 'package:tennis_management/features/booking/domain/models/court_model.dart';
import 'package:tennis_management/features/booking/presentation/providers/booking_provider.dart';
import 'package:tennis_management/features/booking/presentation/screens/book_court_screen.dart';
import 'package:tennis_management/features/payment/presentation/widgets/payment_dialog.dart';
import 'package:tennis_management/features/student/presentation/providers/student_provider.dart';
import 'package:tennis_management/features/tenant/domain/models/tenant_model.dart';

class TestTenantNotifier extends TenantNotifier {
  @override
  AsyncValue<String?> build() {
    return const AsyncValue.data('tenant-1');
  }
}

void main() {
  group('BookCourtScreen', () {
    testWidgets('shows syncing overlay immediately after payment starts', (
      WidgetTester tester,
    ) async {
      final court = CourtModel(
        id: 'court-1',
        name: 'Court 1',
        type: 'tennis',
        pricePerHour: 20000,
      );
      final selectedDate = DateTime.now().add(const Duration(days: 1));
      final selectedTime = const TimeOfDay(hour: 10, minute: 0);
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
          tenantNotifierProvider.overrideWith(TestTenantNotifier.new),
          hasTenantProvider.overrideWith((ref) => true),
          currentTenantProvider.overrideWith((ref) async => testTenant),
          courtsProvider.overrideWith((ref) async => [court]),
          courtAvailableSlotsProvider.overrideWith(
            (ref, params) async => {
              'availableSlots': ['10:00'],
              'bookedSlots': <String>[],
            },
          ),
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 0,
              'totalSpent': 0,
              'totalClasses': 0,
              'totalPayments': 0,
            },
          ),
          myBookingsProvider.overrideWith((ref) async => <BookingModel>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: BookCourtScreen(
              initialCourt: court,
              initialDate: selectedDate,
              initialTime: selectedTime,
              paymentDialogBuilder: (context, amount, onPaymentStart) {
                return Builder(
                  builder: (dialogContext) {
                    Future.microtask(() {
                      onPaymentStart();
                      Navigator.of(dialogContext).pop(true);
                    });
                    return const SizedBox.shrink();
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pump();

      await tester.ensureVisible(find.text('Recargar y Reservar'));
      await tester.tap(find.text('Recargar y Reservar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Procesando reserva...'), findsOneWidget);

      await tester.pumpWidget(Container());
      container.dispose();
    });

    testWidgets('stops syncing when payment fails', (
      WidgetTester tester,
    ) async {
      final court = CourtModel(
        id: 'court-1',
        name: 'Court 1',
        type: 'tennis',
        pricePerHour: 20000,
      );
      final selectedDate = DateTime.now().add(const Duration(days: 1));
      final selectedTime = const TimeOfDay(hour: 10, minute: 0);
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
          tenantNotifierProvider.overrideWith(TestTenantNotifier.new),
          hasTenantProvider.overrideWith((ref) => true),
          currentTenantProvider.overrideWith((ref) async => testTenant),
          courtsProvider.overrideWith((ref) async => [court]),
          courtAvailableSlotsProvider.overrideWith(
            (ref, params) async => {
              'availableSlots': ['10:00'],
              'bookedSlots': <String>[],
            },
          ),
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 0,
              'totalSpent': 0,
              'totalClasses': 0,
              'totalPayments': 0,
            },
          ),
          myBookingsProvider.overrideWith((ref) async => <BookingModel>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: BookCourtScreen(
              initialCourt: court,
              initialDate: selectedDate,
              initialTime: selectedTime,
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

      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      await tester.pumpWidget(Container());
      container.dispose();
    });

    testWidgets('stops syncing when payment is pending', (
      WidgetTester tester,
    ) async {
      final court = CourtModel(
        id: 'court-1',
        name: 'Court 1',
        type: 'tennis',
        pricePerHour: 20000,
      );
      final selectedDate = DateTime.now().add(const Duration(days: 1));
      final selectedTime = const TimeOfDay(hour: 10, minute: 0);
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
          tenantNotifierProvider.overrideWith(TestTenantNotifier.new),
          hasTenantProvider.overrideWith((ref) => true),
          currentTenantProvider.overrideWith((ref) async => testTenant),
          courtsProvider.overrideWith((ref) async => [court]),
          courtAvailableSlotsProvider.overrideWith(
            (ref, params) async => {
              'availableSlots': ['10:00'],
              'bookedSlots': <String>[],
            },
          ),
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 0,
              'totalSpent': 0,
              'totalClasses': 0,
              'totalPayments': 0,
            },
          ),
          myBookingsProvider.overrideWith((ref) async => <BookingModel>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: BookCourtScreen(
              initialCourt: court,
              initialDate: selectedDate,
              initialTime: selectedTime,
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

      dialog.onPaymentPending?.call();
      await tester.pump();

      expect(find.text('Procesando reserva...'), findsNothing);

      await tester.tap(find.text('Cancelar'));
      await tester.pump();

      await tester.pumpWidget(Container());
      container.dispose();
    });

    testWidgets('should pass redirectUrl to PaymentDialog', (
      WidgetTester tester,
    ) async {
      final court = CourtModel(
        id: 'court-1',
        name: 'Court 1',
        type: 'tennis',
        pricePerHour: 20000,
      );
      final selectedDate = DateTime.now().add(const Duration(days: 1));
      final selectedTime = const TimeOfDay(hour: 10, minute: 0);
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
          tenantNotifierProvider.overrideWith(TestTenantNotifier.new),
          hasTenantProvider.overrideWith((ref) => true),
          currentTenantProvider.overrideWith((ref) async => testTenant),
          courtsProvider.overrideWith((ref) async => [court]),
          courtAvailableSlotsProvider.overrideWith(
            (ref, params) async => {
              'availableSlots': ['10:00'],
              'bookedSlots': <String>[],
            },
          ),
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 0,
              'totalSpent': 0,
              'totalClasses': 0,
              'totalPayments': 0,
            },
          ),
          myBookingsProvider.overrideWith((ref) async => <BookingModel>[]),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: BookCourtScreen(
              initialCourt: court,
              initialDate: selectedDate,
              initialTime: selectedTime,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Recargar y Reservar'));
      await tester.tap(find.text('Recargar y Reservar'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final dialog = tester.widget<PaymentDialog>(find.byType(PaymentDialog));
      expect(dialog.redirectUrl, equals(AppConfig.paymentRedirectUrl));

      await tester.pumpWidget(Container());
      container.dispose();
    });
  });
}

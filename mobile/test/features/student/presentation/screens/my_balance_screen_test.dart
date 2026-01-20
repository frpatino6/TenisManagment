import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tennis_management/core/providers/tenant_provider.dart';
import 'package:tennis_management/features/payment/presentation/widgets/payment_dialog.dart';
import 'package:tennis_management/features/student/presentation/providers/student_provider.dart';
import 'package:tennis_management/features/student/presentation/screens/my_balance_screen.dart';
import 'package:tennis_management/features/tenant/domain/models/tenant_model.dart';

void main() {
  group('MyBalanceScreen', () {
    testWidgets('should show syncing overlay when balance is syncing', (
      WidgetTester tester,
    ) async {
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
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 10000,
              'totalSpent': 20000,
              'totalClasses': 3,
              'totalPayments': 2,
            },
          ),
          currentTenantProvider.overrideWith((ref) async => testTenant),
        ],
      );

      container.read(balanceSyncProvider.notifier).start();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MyBalanceScreen()),
        ),
      );

      await tester.pump();
      await tester.pump();

      expect(find.text('Actualizando saldo...'), findsOneWidget);

      await tester.pumpWidget(Container());
      container.dispose();
    });

    testWidgets('should pass redirectUrl to PaymentDialog', (
      WidgetTester tester,
    ) async {
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
          studentInfoProvider.overrideWith(
            (ref) async => {
              'balance': 10000,
              'totalSpent': 20000,
              'totalClasses': 3,
              'totalPayments': 2,
            },
          ),
          currentTenantProvider.overrideWith((ref) async => testTenant),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: MyBalanceScreen()),
        ),
      );

      await tester.pumpAndSettle();

      await tester.tap(find.text('Recargar Saldo'));
      await tester.pumpAndSettle();

      final dialog = tester.widget<PaymentDialog>(find.byType(PaymentDialog));
      expect(
        dialog.redirectUrl,
        equals('https://tenis-uat.casacam.net/payment-complete'),
      );

      await tester.pumpWidget(Container());
      container.dispose();
    });
  });
}

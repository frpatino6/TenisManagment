import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/tenant_payment_model.dart';
import 'package:tennis_management/features/tenant_admin/presentation/providers/tenant_admin_provider.dart';
import 'package:tennis_management/features/tenant_admin/presentation/screens/tenant_payments_list_screen.dart';

void main() {
  testWidgets('shows payments list with refresh action', (tester) async {
    final response = TenantPaymentsResponse(
      payments: [
        TenantPaymentModel(
          id: 'p1',
          reference: 'TRX-1',
          amount: 50000,
          currency: 'COP',
          status: 'APPROVED',
          gateway: 'WOMPI',
          date: DateTime(2026, 1, 10),
        ),
      ],
      pagination: PaymentsPagination(
        page: 1,
        limit: 20,
        total: 1,
        totalPages: 1,
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantPaymentsProvider.overrideWithValue(AsyncValue.data(response)),
        ],
        child: const MaterialApp(home: TenantPaymentsListScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Pagos'), findsOneWidget);
    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.text('TRX-1'), findsOneWidget);
  });
}

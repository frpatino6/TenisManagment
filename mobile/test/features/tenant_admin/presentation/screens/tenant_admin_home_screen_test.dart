import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/tenant_metrics_model.dart';
import 'package:tennis_management/features/tenant_admin/presentation/providers/tenant_admin_provider.dart';
import 'package:tennis_management/features/tenant_admin/presentation/screens/tenant_admin_home_screen.dart';

void main() {
  testWidgets('shows billing action in quick actions', (tester) async {
    final metrics = TenantMetricsModel(
      bookings: const BookingsMetrics(total: 10),
      payments: const PaymentsMetrics(total: 5, revenue: 1200),
      users: const UsersMetrics(professors: 2, students: 12),
      courts: const CourtsMetrics(total: 3),
      topProfessors: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          tenantMetricsProvider.overrideWithValue(AsyncValue.data(metrics)),
        ],
        child: const MaterialApp(home: TenantAdminHomeScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Facturación'), findsOneWidget);
    expect(find.text('Ver ingresos'), findsOneWidget);
  });
}

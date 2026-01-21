import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/booking_stats_model.dart';
import 'package:tennis_management/features/tenant_admin/presentation/providers/tenant_admin_provider.dart';
import 'package:tennis_management/features/tenant_admin/presentation/screens/tenant_booking_stats_screen.dart';

void main() {
  testWidgets('shows refresh and revenue summary on booking stats', (
    tester,
  ) async {
    final stats = BookingStatsModel(
      total: 1,
      totalRevenue: 50000,
      averagePrice: 50000,
      byStatus: {'confirmed': StatusStats(count: 1, revenue: 50000)},
      byServiceType: {
        'court_rental': ServiceTypeStats(count: 1, revenue: 50000),
      },
      topCourts: const [],
      topProfessors: const [],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          bookingStatsProvider.overrideWithValue(AsyncValue.data(stats)),
        ],
        child: const MaterialApp(home: TenantBookingStatsScreen()),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.refresh), findsOneWidget);
    expect(find.text('Consolidado de ingresos'), findsOneWidget);
    expect(find.text('Totales por servicio'), findsOneWidget);
    expect(find.text('Totales por estado'), findsOneWidget);
    expect(find.text('Alquiler de cancha'), findsOneWidget);
    expect(find.text('Confirmadas'), findsOneWidget);
    expect(find.text('Ver detalle'), findsOneWidget);
  });
}

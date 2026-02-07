import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tennis_management/features/tenant_admin/domain/models/booking_stats_model.dart';
import 'package:tennis_management/features/tenant_admin/presentation/providers/tenant_admin_provider.dart';
import 'package:tennis_management/features/tenant_admin/presentation/screens/tenant_booking_stats_screen.dart';

void main() {
  testWidgets('shows executive billing summary', (tester) async {
    final stats = BookingStatsModel(
      total: 1,
      totalRevenue: 50000,
      averagePrice: 50000,
      walletRevenue: 20000,
      directRevenue: 30000,
      revenueTrend: [
        RevenueTrendPoint(date: '2026-01-01', revenue: 10000),
        RevenueTrendPoint(date: '2026-01-02', revenue: 40000),
      ],
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
    expect(find.text('Ingresos Netos Totales'), findsOneWidget);
    expect(find.text('Rendimiento Financiero'), findsOneWidget);
    expect(find.text('Desglose Ejecutivo'), findsOneWidget);
    expect(find.text('Alquiler de cancha'), findsWidgets);
    expect(find.text('Ver detalle'), findsOneWidget);
    expect(find.text('7 días'), findsOneWidget);
    expect(find.text('30 días'), findsOneWidget);
    expect(find.text('90 días'), findsOneWidget);
  });
}

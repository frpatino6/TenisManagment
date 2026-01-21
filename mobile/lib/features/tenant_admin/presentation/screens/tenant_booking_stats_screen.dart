import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import '../../../../core/utils/currency_utils.dart';
import '../../../../core/widgets/loading_widget.dart';
import '../../../../core/widgets/error_widget.dart';
import '../providers/tenant_admin_provider.dart';
import '../../domain/models/booking_stats_model.dart';

class TenantBookingStatsScreen extends ConsumerWidget {
  const TenantBookingStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(bookingStatsProvider);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Estadísticas de Reservas'),
        actions: [
          IconButton(
            onPressed: () => ref.refresh(bookingStatsProvider),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: statsAsync.when(
        data: (bookingStats) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Summary cards row
                Row(
                  children: [
                    Expanded(
                      child: _buildMiniSummaryCard(
                        context,
                        'Total',
                        bookingStats.total.toString(),
                        Icons.event,
                        colorScheme.primary,
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: _buildMiniSummaryCard(
                        context,
                        'Ingresos',
                        '\$${bookingStats.totalRevenue.toStringAsFixed(0)}',
                        Icons.attach_money,
                        Colors.green,
                      ),
                    ),
                  ],
                ),
                const Gap(24),

                // Distribution Chart (Pie)
                _buildSectionHeader(context, 'Distribución por Estado'),
                const Gap(12),
                _buildStatusPieChart(context, bookingStats),
                const Gap(24),

                // Revenue by Service (Bar)
                _buildSectionHeader(context, 'Ingresos por Servicio'),
                const Gap(12),
                _buildServiceTypeBarChart(context, bookingStats),
                const Gap(24),

                _buildSectionHeader(context, 'Consolidado de ingresos'),
                const Gap(12),
                _buildRevenueSummaryCard(context, bookingStats),
                const Gap(24),

                _buildSectionHeader(context, 'Totales por servicio'),
                const Gap(12),
                _buildTotalsByService(context, bookingStats),
                const Gap(24),

                _buildSectionHeader(context, 'Totales por estado'),
                const Gap(12),
                _buildTotalsByStatus(context, bookingStats),
              ],
            ),
          );
        },
        loading: () => const LoadingWidget(),
        error: (error, stack) => AppErrorWidget.fromError(
          error,
          onRetry: () => ref.refresh(bookingStatsProvider),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildMiniSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const Gap(12),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSummaryCard(
    BuildContext context,
    BookingStatsModel stats,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total facturado',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const Gap(8),
            Text(
              CurrencyUtils.format(stats.totalRevenue),
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.primary,
              ),
            ),
            const Gap(8),
            Text(
              'Ticket promedio: ${CurrencyUtils.format(stats.averagePrice)}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const Gap(12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => context.push('/tenant-admin-home/bookings'),
                icon: const Icon(Icons.receipt_long),
                label: const Text('Ver detalle'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsByService(BuildContext context, BookingStatsModel stats) {
    if (stats.byServiceType.isEmpty) {
      return _buildEmptyTotalsCard(context, 'Sin datos por servicio');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: stats.byServiceType.entries.map((entry) {
            final label = _serviceLabel(entry.key);
            return _buildTotalsRow(
              context,
              label: label,
              count: entry.value.count,
              amount: entry.value.revenue,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildTotalsByStatus(BuildContext context, BookingStatsModel stats) {
    if (stats.byStatus.isEmpty) {
      return _buildEmptyTotalsCard(context, 'Sin datos por estado');
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            if (stats.byStatus.containsKey('confirmed'))
              _buildTotalsRow(
                context,
                label: 'Confirmadas',
                count: stats.confirmedCount,
                amount: stats.confirmedRevenue,
              ),
            if (stats.byStatus.containsKey('completed'))
              _buildTotalsRow(
                context,
                label: 'Completadas',
                count: stats.completedCount,
                amount: stats.completedRevenue,
              ),
            if (stats.byStatus.containsKey('pending'))
              _buildTotalsRow(
                context,
                label: 'Pendientes',
                count: stats.pendingCount,
                amount: stats.pendingRevenue,
              ),
            if (stats.byStatus.containsKey('cancelled'))
              _buildTotalsRow(
                context,
                label: 'Canceladas',
                count: stats.cancelledCount,
                amount: stats.byStatus['cancelled']?.revenue ?? 0,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsRow(
    BuildContext context, {
    required String label,
    required int count,
    required double amount,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            '$count',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(12),
          Text(
            CurrencyUtils.format(amount),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTotalsCard(BuildContext context, String message) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
      ),
    );
  }

  String _serviceLabel(String key) {
    switch (key) {
      case 'court_rental':
        return 'Alquiler de cancha';
      case 'individual_class':
        return 'Clase individual';
      case 'group_class':
        return 'Clase grupal';
      default:
        return key;
    }
  }

  Widget _buildStatusPieChart(BuildContext context, BookingStatsModel stats) {
    final total = stats.total == 0 ? 1 : stats.total;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                  sections: [
                    if (stats.confirmedCount > 0)
                      PieChartSectionData(
                        value: stats.confirmedCount.toDouble(),
                        title:
                            '${(stats.confirmedCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.green,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (stats.pendingCount > 0)
                      PieChartSectionData(
                        value: stats.pendingCount.toDouble(),
                        title:
                            '${(stats.pendingCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.orange,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (stats.completedCount > 0)
                      PieChartSectionData(
                        value: stats.completedCount.toDouble(),
                        title:
                            '${(stats.completedCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.blue,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (stats.cancelledCount > 0)
                      PieChartSectionData(
                        value: stats.cancelledCount.toDouble(),
                        title:
                            '${(stats.cancelledCount / total * 100).toStringAsFixed(0)}%',
                        color: Colors.red,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    if (stats.total == 0)
                      PieChartSectionData(
                        value: 1,
                        title: '0%',
                        color: Colors.grey[300]!,
                        radius: 50,
                        titleStyle: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const Gap(24),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                _buildLegendItem('Confirmadas', Colors.green),
                _buildLegendItem('Pendientes', Colors.orange),
                _buildLegendItem('Completadas', Colors.blue),
                _buildLegendItem('Canceladas', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceTypeBarChart(
    BuildContext context,
    BookingStatsModel stats,
  ) {
    final types = stats.byServiceType.entries.toList();
    if (types.isEmpty) return const SizedBox();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY:
                      types
                          .map((e) => e.value.revenue)
                          .reduce((a, b) => a > b ? a : b) *
                      1.2,
                  barTouchData: BarTouchData(enabled: true),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value.toInt() < 0 ||
                              value.toInt() >= types.length) {
                            return const SizedBox();
                          }
                          final label = _getServiceTypeLabel(
                            types[value.toInt()].key,
                          );
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              label.substring(0, 3).toUpperCase(),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: types.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value.value.revenue,
                          color: Theme.of(context).colorScheme.primary,
                          width: 22,
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(6),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
            const Gap(16),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: types
                  .map(
                    (e) => Text(
                      '${e.key.substring(0, 3).toUpperCase()}: ${_getServiceTypeLabel(e.key)}',
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const Gap(6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  String _getServiceTypeLabel(String serviceType) {
    switch (serviceType) {
      case 'individual_class':
        return 'Clases Individuales';
      case 'group_class':
        return 'Clases Grupales';
      case 'court_rental':
        return 'Alquiler de Canchas';
      default:
        return serviceType;
    }
  }
}

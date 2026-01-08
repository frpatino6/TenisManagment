import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
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
      appBar: AppBar(title: const Text('Estadísticas de Reservas')),
      body: statsAsync.when(
        data: (stats) {
          final bookingStats = stats as BookingStatsModel;

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

                // Top Courts
                if (bookingStats.topCourts.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Canchas más rentables'),
                  const Gap(12),
                  ...bookingStats.topCourts
                      .take(3)
                      .map(
                        (court) => _buildTopItem(
                          context,
                          court.courtName,
                          '${court.bookingsCount} reservas',
                          '\$${court.revenue.toStringAsFixed(0)}',
                          Icons.sports_tennis,
                        ),
                      ),
                  const Gap(24),
                ],

                // Top Professors
                if (bookingStats.topProfessors.isNotEmpty) ...[
                  _buildSectionHeader(context, 'Profesores más activos'),
                  const Gap(12),
                  ...bookingStats.topProfessors
                      .take(3)
                      .map(
                        (prof) => _buildTopItem(
                          context,
                          prof.professorName,
                          '${prof.bookingsCount} reservas',
                          '\$${prof.revenue.toStringAsFixed(0)}',
                          Icons.person,
                        ),
                      ),
                ],
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

  Widget _buildTopItem(
    BuildContext context,
    String name,
    String subtitle,
    String revenue,
    IconData icon,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 20),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: Text(
          revenue,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.green,
          ),
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

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
                // Summary cards
                _buildSummaryCard(
                  context,
                  'Total Reservas',
                  bookingStats.total.toString(),
                  Icons.event,
                  colorScheme.primary,
                ),
                const Gap(12),
                _buildSummaryCard(
                  context,
                  'Ingresos Totales',
                  '\$${bookingStats.totalRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  Colors.green,
                ),
                const Gap(12),
                _buildSummaryCard(
                  context,
                  'Precio Promedio',
                  '\$${bookingStats.averagePrice.toStringAsFixed(0)}',
                  Icons.trending_up,
                  Colors.blue,
                ),
                const Gap(24),

                // By Status
                Text(
                  'Por Estado',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),
                _buildStatusStats(context, bookingStats),
                const Gap(24),

                // By Service Type
                Text(
                  'Por Tipo de Servicio',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Gap(12),
                _buildServiceTypeStats(context, bookingStats),
                const Gap(24),

                // Top Courts
                if (bookingStats.topCourts.isNotEmpty) ...[
                  Text(
                    'Canchas Más Reservadas',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(12),
                  ...bookingStats.topCourts.map(
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
                  Text(
                    'Profesores Más Activos',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(12),
                  ...bookingStats.topProfessors.map(
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

  Widget _buildSummaryCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 32),
            ),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStats(BuildContext context, BookingStatsModel stats) {
    final statusData = [
      (
        'Confirmadas',
        stats.confirmedCount,
        stats.confirmedRevenue,
        Colors.green,
      ),
      ('Pendientes', stats.pendingCount, stats.pendingRevenue, Colors.orange),
      (
        'Completadas',
        stats.completedCount,
        stats.completedRevenue,
        Colors.blue,
      ),
      ('Canceladas', stats.cancelledCount, 0.0, Colors.red),
    ];

    return Column(
      children: statusData.map((data) {
        final (label, count, revenue, color) = data;
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.withOpacity(0.2),
              child: Text(
                count.toString(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(label),
            trailing: Text(
              '\$${revenue.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServiceTypeStats(BuildContext context, BookingStatsModel stats) {
    final serviceTypes = stats.byServiceType.entries.toList();

    return Column(
      children: serviceTypes.map((entry) {
        final label = _getServiceTypeLabel(entry.key);
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: const Icon(Icons.category),
            title: Text(label),
            subtitle: Text('${entry.value.count} reservas'),
            trailing: Text(
              '\$${entry.value.revenue.toStringAsFixed(0)}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        );
      }).toList(),
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
      child: ListTile(
        leading: Icon(icon),
        title: Text(name),
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

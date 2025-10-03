import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../data/providers/analytics_provider.dart';
import '../widgets/analytics_metric_card.dart';
import '../widgets/analytics_chart_widget.dart';
import '../widgets/analytics_filter_bar.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh data when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      refreshAnalytics(ref);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final filters = ref.watch(analyticsFiltersProvider);

    final analyticsAsync = ref.watch(analyticsOverviewProvider(filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Analytics'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => refreshAnalytics(ref),
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar datos',
          ),
        ],
      ),
      body: analyticsAsync.when(
        data: (analytics) => _buildDashboard(context, analytics),
        loading: () => _buildLoadingState(context),
        error: (error, stackTrace) => _buildErrorState(context, error),
      ),
    );
  }

  Widget _buildDashboard(BuildContext context, analytics) {
    final theme = Theme.of(context);
    final filters = ref.watch(analyticsFiltersProvider);

    return RefreshIndicator(
      onRefresh: () async {
        refreshAnalytics(ref);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Filter bar
            AnalyticsFilterBar(
              selectedPeriod: filters['period'] ?? 'month',
              selectedServiceType: filters['serviceType'],
              selectedStatus: filters['status'],
              onPeriodChanged: (period) {
                ref.read(analyticsFiltersProvider.notifier).updateFilters({
                  ...filters,
                  'period': period,
                });
                refreshAnalytics(ref);
              },
              onServiceTypeChanged: (serviceType) {
                ref.read(analyticsFiltersProvider.notifier).updateFilters({
                  ...filters,
                  'serviceType': serviceType,
                });
                refreshAnalytics(ref);
              },
              onStatusChanged: (status) {
                ref.read(analyticsFiltersProvider.notifier).updateFilters({
                  ...filters,
                  'status': status,
                });
                refreshAnalytics(ref);
              },
              onRefresh: () => refreshAnalytics(ref),
            ),
            const Gap(16),

            // Last updated info
            _buildLastUpdatedInfo(context, analytics.lastUpdated),
            const Gap(16),

            // Metrics cards
            _buildMetricsSection(context, analytics.metrics),
            const Gap(24),

            // Charts section
            _buildChartsSection(context, analytics.charts),
            const Gap(24),

            // Quick actions
            _buildQuickActionsSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildLastUpdatedInfo(BuildContext context, DateTime lastUpdated) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.update, size: 16, color: colorScheme.onSurfaceVariant),
          const Gap(8),
          Text(
            'Última actualización: ${_formatDateTime(lastUpdated)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricsSection(BuildContext context, metrics) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Métricas Principales',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.5,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
          ),
          itemCount: metrics.length,
          itemBuilder: (context, index) {
            return AnalyticsMetricCard(
              metric: metrics[index],
              onTap: () {
                // TODO: Navigate to detailed view
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Ver detalles de ${metrics[index].title}'),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildChartsSection(BuildContext context, charts) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (charts.isEmpty) {
      return _buildEmptyChartsState(context);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Análisis Detallado',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(12),
        ...charts.map(
          (chart) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: AnalyticsChartWidget(chartData: chart, height: 250),
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Acciones Rápidas',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          ),
        ),
        const Gap(12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  // TODO: Export data
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de exportar en desarrollo'),
                    ),
                  );
                },
                icon: const Icon(Icons.download),
                label: const Text('Exportar Datos'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  // TODO: Share report
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Función de compartir en desarrollo'),
                    ),
                  );
                },
                icon: const Icon(Icons.share),
                label: const Text('Compartir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: colorScheme.primary,
                  side: BorderSide(color: colorScheme.primary),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: colorScheme.primary),
          const Gap(16),
          Text(
            'Cargando analytics...',
            style: theme.textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: colorScheme.error),
            const Gap(16),
            Text(
              'Error al cargar analytics',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const Gap(24),
            ElevatedButton(
              onPressed: () => refreshAnalytics(ref),
              child: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyChartsState(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 64,
              color: colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const Gap(16),
            Text(
              'No hay datos de gráficos disponibles',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const Gap(8),
            Text(
              'Los gráficos aparecerán cuando tengas más datos.',
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'Hace un momento';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} minutos';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} horas';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}

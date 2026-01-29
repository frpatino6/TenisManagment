import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../providers/analytics_provider.dart';
import '../../domain/models/analytics_error.dart';
import '../widgets/analytics_metric_card.dart';
import '../widgets/analytics_chart_widget.dart';
import '../widgets/analytics_filter_bar.dart';
import '../widgets/analytics_loading_widget.dart';
import '../widgets/analytics_error_widget.dart';
import 'metric_detail_screen.dart';

class AnalyticsDashboardScreen extends ConsumerStatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  ConsumerState<AnalyticsDashboardScreen> createState() =>
      _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState
    extends ConsumerState<AnalyticsDashboardScreen> {
  Map<String, String?> _filters = {
    'period': 'month',
    'serviceType': null,
    'status': null,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAnalytics();
    });
  }

  void _refreshAnalytics() {
    final period = _filters['period'] ?? 'month';

    ref.invalidate(analyticsOverviewProvider(_filters));
    ref.invalidate(analyticsRevenueProvider(period));
    ref.invalidate(analyticsBookingsProvider(period));
    ref.invalidate(analyticsStudentsProvider(period));
  }

  void _updateFilters(Map<String, String?> newFilters) {
    setState(() {
      _filters = newFilters;
    });
    _refreshAnalytics();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final analyticsAsync = ref.watch(analyticsOverviewProvider(_filters));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard de Analytics'),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: _refreshAnalytics,
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
    return RefreshIndicator(
      onRefresh: () async {
        _refreshAnalytics();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnalyticsFilterBar(
              selectedPeriod: _filters['period'] ?? 'month',
              selectedServiceType: _filters['serviceType'],
              selectedStatus: _filters['status'],
              onPeriodChanged: (period) {
                _updateFilters({..._filters, 'period': period});
              },
              onServiceTypeChanged: (serviceType) {
                _updateFilters({..._filters, 'serviceType': serviceType});
              },
              onStatusChanged: (status) {
                _updateFilters({..._filters, 'status': status});
              },
              onRefresh: _refreshAnalytics,
            ),
            const Gap(16),
            _buildLastUpdatedInfo(context, analytics.lastUpdated),
            const Gap(16),
            _buildMetricsSection(context, analytics.metrics),
            const Gap(24),
            _buildChartsSection(context, analytics.charts),
            const Gap(24),
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
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: const BorderRadius.all(Radius.circular(8)),
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
        if (metrics.isEmpty)
          const AnalyticsSkeletonLoading(
            itemCount: 4,
            type: SkeletonType.metric,
          )
        else
          LayoutBuilder(
            builder: (context, constraints) {
              const crossAxisCount = 2;
              const childAspectRatio = 1.2;
              const crossAxisSpacing = 8.0;
              const mainAxisSpacing = 8.0;

              final itemWidth =
                  (constraints.maxWidth - crossAxisSpacing) / crossAxisCount;
              final itemHeight = itemWidth / childAspectRatio;
              final rowCount = (metrics.length / crossAxisCount).ceil();
              final totalHeight =
                  (rowCount * itemHeight) + ((rowCount - 1) * mainAxisSpacing);

              return SizedBox(
                height: totalHeight,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 1.2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                  ),
                  itemCount: metrics.length,
                  itemBuilder: (context, index) {
                    final metric = metrics[index];
                    return AnalyticsMetricCard(
                      key: ValueKey(
                        'metric_${metric.title}_${metric.icon}_$index',
                      ),
                      metric: metric,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                MetricDetailScreen(metric: metric),
                          ),
                        );
                      },
                    );
                  },
                ),
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
    return AnalyticsLoadingWidget(
      type: LoadingType.overview,
      title: 'Cargando Dashboard de Analytics',
      subtitle: 'Obteniendo métricas y gráficos actualizados',
      steps: [
        'Conectando con el servidor',
        'Obteniendo datos de métricas',
        'Generando gráficos',
        'Finalizando carga',
      ],
      currentStep: 2,
    );
  }

  Widget _buildErrorState(BuildContext context, Object error) {
    AnalyticsError? analyticsError;
    try {
      if (error is AnalyticsError) {
        analyticsError = error;
      } else {
        analyticsError = AnalyticsError(
          type: AnalyticsErrorType.unknownError,
          message: 'Error al cargar analytics',
          details: error.toString(),
          endpoint: 'analytics-overview',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      analyticsError = AnalyticsError(
        type: AnalyticsErrorType.unknownError,
        message: 'Error inesperado',
        details: error.toString(),
        endpoint: 'analytics-overview',
        timestamp: DateTime.now(),
      );
    }

    return AnalyticsErrorWidget(
      error: analyticsError,
      onRetry: _refreshAnalytics,
      showDetails: true,
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
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
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

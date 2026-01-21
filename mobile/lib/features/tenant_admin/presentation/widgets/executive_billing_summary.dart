import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../domain/models/booking_stats_model.dart';

class ExecutiveBillingSummary extends StatelessWidget {
  final BookingStatsModel stats;
  final VoidCallback onViewDetails;

  const ExecutiveBillingSummary({
    super.key,
    required this.stats,
    required this.onViewDetails,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 600;
        final spacing = isWide ? 24.0 : 16.0;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeroSection(context),
              Gap(spacing),
              _buildPerformanceSection(context, isWide),
              Gap(spacing),
              _buildChartsSection(context, isWide),
              Gap(spacing),
              _buildExecutiveTable(context),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final trend = _calculateTrendChange(stats.revenueTrend);
    final isPositive = trend >= 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withValues(alpha: 0.25),
            colorScheme.primary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ingresos Netos Totales',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton(
                onPressed: onViewDetails,
                child: const Text('Ver detalle'),
              ),
            ],
          ),
          const Gap(8),
          Text(
            _formatCurrency(stats.totalRevenue),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const Gap(8),
          Align(
            alignment: Alignment.centerLeft,
            child: Chip(
              label: Text(
                '${isPositive ? '+' : ''}${trend.toStringAsFixed(0)}% vs período anterior',
                style: TextStyle(
                  color: isPositive ? Colors.green : colorScheme.error,
                ),
              ),
              backgroundColor: (isPositive ? Colors.green : colorScheme.error)
                  .withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceSection(BuildContext context, bool isWide) {
    final colorScheme = Theme.of(context).colorScheme;
    final walletRevenue = stats.walletRevenue;
    final walletPenetration = stats.totalRevenue == 0
        ? 0
        : (walletRevenue / stats.totalRevenue) * 100;
    final commissionSavings = walletRevenue * 0.03;

    final metrics = [
      _MetricCardData(
        title: 'Ticket Promedio',
        value: _formatCurrency(stats.averagePrice),
        icon: Icons.receipt_long,
      ),
      _MetricCardData(
        title: 'Ahorro por Monedero',
        value: _formatCurrency(commissionSavings),
        icon: Icons.savings_outlined,
      ),
      _MetricCardData(
        title: 'Penetración Monedero',
        value: '${walletPenetration.toStringAsFixed(1)}%',
        icon: Icons.account_balance_wallet_outlined,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Rendimiento Financiero',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Gap(12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: metrics.map((metric) {
            return SizedBox(
              width: isWide ? 220 : double.infinity,
              child: _buildMetricCard(context, metric, colorScheme),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricCard(
    BuildContext context,
    _MetricCardData metric,
    ColorScheme colorScheme,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(metric.icon, color: colorScheme.primary),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  metric.title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const Gap(4),
                Text(
                  metric.value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(BuildContext context, bool isWide) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tendencia e Ingresos',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const Gap(12),
        isWide
            ? Row(
                children: [
                  Expanded(child: _buildTrendChart(context)),
                  const Gap(16),
                  Expanded(child: _buildServiceDistribution(context)),
                ],
              )
            : Column(
                children: [
                  _buildTrendChart(context),
                  const Gap(16),
                  _buildServiceDistribution(context),
                ],
              ),
      ],
    );
  }

  Widget _buildTrendChart(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final spots = stats.revenueTrend.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.revenue);
    }).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ingresos por periodo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Gap(12),
          SizedBox(
            height: 180,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(show: false),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: spots,
                    isCurved: true,
                    color: colorScheme.primary,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: colorScheme.primary.withValues(alpha: 0.12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceDistribution(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalRevenue = stats.totalRevenue == 0 ? 1 : stats.totalRevenue;
    final entries = stats.byServiceType.entries.toList();

    final colors = [
      colorScheme.primary,
      Colors.teal,
      Colors.orange,
      Colors.purple,
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Distribución de servicios',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Gap(12),
          SizedBox(
            height: 180,
            child: PieChart(
              PieChartData(
                sectionsSpace: 4,
                centerSpaceRadius: 40,
                sections: entries.asMap().entries.map((entry) {
                  final index = entry.key;
                  final data = entry.value;
                  final percent = (data.value.revenue / totalRevenue) * 100;

                  return PieChartSectionData(
                    value: data.value.revenue,
                    color: colors[index % colors.length],
                    title: '${percent.toStringAsFixed(0)}%',
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const Gap(12),
          Column(
            children: entries.asMap().entries.map((entry) {
              final index = entry.key;
              final data = entry.value;
              final percent = (data.value.revenue / totalRevenue) * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colors[index % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const Gap(8),
                    Expanded(
                      child: Text(_serviceLabel(data.key)),
                    ),
                    Text(_formatCurrency(data.value.revenue)),
                    const Gap(8),
                    Text('${percent.toStringAsFixed(1)}%'),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildExecutiveTable(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final totalRevenue = stats.totalRevenue == 0 ? 1 : stats.totalRevenue;
    final rows = stats.byServiceType.entries.toList()
      ..sort((a, b) => b.value.revenue.compareTo(a.value.revenue));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Desglose Ejecutivo',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
          const Gap(12),
          Row(
            children: [
              const SizedBox(width: 24),
              const Gap(8),
              Expanded(
                child: Text(
                  'Servicio',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              _tableHeader(context, 'Cant.'),
              const Gap(12),
              _tableHeader(context, 'Total'),
              const Gap(12),
              _tableHeader(context, '%'),
            ],
          ),
          const Divider(height: 16),
          ...rows.map((entry) {
            final percent = (entry.value.revenue / totalRevenue) * 100;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Icon(
                    _serviceIcon(entry.key),
                    size: 18,
                    color: colorScheme.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(_serviceLabel(entry.key)),
                  ),
                  SizedBox(
                    width: 48,
                    child: Text(
                      entry.value.count.toString(),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: 96,
                    child: Text(
                      _formatCurrency(entry.value.revenue),
                      textAlign: TextAlign.end,
                    ),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: 48,
                    child: Text(
                      '${percent.toStringAsFixed(0)}%',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _tableHeader(BuildContext context, String label) {
    return SizedBox(
      width: 48,
      child: Text(
        label,
        textAlign: TextAlign.end,
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatter = NumberFormat.currency(locale: 'es_CO', symbol: '\$');
    return formatter.format(value);
  }

  double _calculateTrendChange(List<RevenueTrendPoint> trend) {
    if (trend.length < 2) {
      return 0;
    }

    if (trend.length >= 14) {
      final lastWeek = trend.sublist(trend.length - 7);
      final previousWeek = trend.sublist(trend.length - 14, trend.length - 7);
      final lastTotal = lastWeek.fold<double>(
        0,
        (sum, item) => sum + item.revenue,
      );
      final previousTotal = previousWeek.fold<double>(
        0,
        (sum, item) => sum + item.revenue,
      );
      if (previousTotal == 0) {
        return lastTotal == 0 ? 0 : 100;
      }
      return ((lastTotal - previousTotal) / previousTotal) * 100;
    }

    final first = trend.first.revenue;
    final last = trend.last.revenue;
    if (first == 0) {
      return last == 0 ? 0 : 100;
    }
    return ((last - first) / first) * 100;
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

  IconData _serviceIcon(String key) {
    switch (key) {
      case 'court_rental':
        return Icons.sports_tennis;
      case 'individual_class':
        return Icons.person;
      case 'group_class':
        return Icons.groups;
      default:
        return Icons.category;
    }
  }
}

class _MetricCardData {
  final String title;
  final String value;
  final IconData icon;

  _MetricCardData({
    required this.title,
    required this.value,
    required this.icon,
  });
}

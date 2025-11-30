import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/analytics_metric.dart';
import '../widgets/metric_detail_widget.dart';

class MetricDetailScreen extends StatelessWidget {
  final AnalyticsMetric metric;

  const MetricDetailScreen({super.key, required this.metric});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(metric.title),
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () => _showExportOptions(context),
            icon: const Icon(Icons.download),
            tooltip: 'Exportar datos',
          ),
        ],
      ),
      body: Column(
        children: [
          _buildMetricHeader(context),
          const Gap(16),
          Expanded(child: MetricDetailWidget(metric: metric)),
        ],
      ),
    );
  }

  Widget _buildMetricHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    Color cardColor;
    try {
      cardColor = Color(int.parse(metric.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      cardColor = colorScheme.primary;
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            cardColor.withValues(alpha: 0.1),
            cardColor.withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cardColor.withValues(alpha: 0.2), width: 1),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cardColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getMetricIcon(metric.icon),
                  color: cardColor,
                  size: 24,
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      metric.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (metric.subtitle != null) ...[
                      const Gap(4),
                      Text(
                        metric.subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const Gap(20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Valor Actual',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface.withValues(alpha: 0.7),
                    ),
                  ),
                  const Gap(4),
                  Text(
                    metric.value,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              if (metric.change != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: metric.isPositive
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        metric.isPositive
                            ? Icons.trending_up
                            : Icons.trending_down,
                        size: 16,
                        color: metric.isPositive ? Colors.green : Colors.red,
                      ),
                      const Gap(4),
                      Text(
                        metric.change!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: metric.isPositive ? Colors.green : Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  IconData _getMetricIcon(String iconName) {
    switch (iconName) {
      case 'money':
        return Icons.attach_money;
      case 'bookings':
        return Icons.calendar_today;
      case 'students':
        return Icons.people;
      case 'occupancy':
        return Icons.analytics;
      default:
        return Icons.analytics;
    }
  }

  void _showExportOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Exportar Datos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const Gap(20),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Exportar como PDF'),
              onTap: () {
                Navigator.pop(context);
                _exportAsPdf(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Exportar como Excel'),
              onTap: () {
                Navigator.pop(context);
                _exportAsExcel(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.image),
              title: const Text('Compartir imagen'),
              onTap: () {
                Navigator.pop(context);
                _shareAsImage(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _exportAsPdf(BuildContext context) {
    // TODO: Implement PDF export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de exportación PDF en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _exportAsExcel(BuildContext context) {
    // TODO: Implement Excel export
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de exportación Excel en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _shareAsImage(BuildContext context) {
    // TODO: Implement image sharing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Función de compartir imagen en desarrollo'),
        backgroundColor: Colors.orange,
      ),
    );
  }
}

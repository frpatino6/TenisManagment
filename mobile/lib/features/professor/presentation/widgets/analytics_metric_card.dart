import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/analytics_metric.dart';

class AnalyticsMetricCard extends StatelessWidget {
  final AnalyticsMetric metric;
  final VoidCallback? onTap;

  const AnalyticsMetricCard({
    super.key,
    required this.metric,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    // Parse color from string
    Color cardColor;
    try {
      cardColor = Color(int.parse(metric.color.replaceFirst('#', '0xFF')));
    } catch (e) {
      cardColor = colorScheme.primary;
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(4),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: cardColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _getIconData(metric.icon),
                      color: cardColor,
                      size: 20,
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          metric.title,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (metric.subtitle != null) ...[
                          const Gap(2),
                          Text(
                            metric.subtitle!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      metric.value,
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ),
                  if (metric.change != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: metric.isPositive
                            ? Colors.green.withOpacity(0.1)
                            : Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            metric.isPositive ? Icons.trending_up : Icons.trending_down,
                            size: 14,
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
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    switch (iconName.toLowerCase()) {
      case 'money':
      case 'revenue':
        return Icons.attach_money;
      case 'bookings':
      case 'classes':
        return Icons.school;
      case 'students':
        return Icons.people;
      case 'schedule':
      case 'occupancy':
        return Icons.schedule;
      case 'growth':
        return Icons.trending_up;
      case 'decline':
        return Icons.trending_down;
      default:
        return Icons.analytics;
    }
  }
}

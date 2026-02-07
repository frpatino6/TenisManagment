import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import '../../domain/models/analytics_metric.dart';

class AnalyticsMetricCard extends StatelessWidget {
  final AnalyticsMetric metric;
  final VoidCallback? onTap;

  const AnalyticsMetricCard({super.key, required this.metric, this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: cardColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      AnalyticsMetricCard._getIconData(metric.icon),
                      color: cardColor,
                      size: 16,
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      metric.title,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Gap(8),

              Text(
                metric.value,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                  fontSize: 18,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),

              if (metric.subtitle != null || metric.change != null) ...[
                const Gap(4),
                Row(
                  children: [
                    if (metric.subtitle != null) ...[
                      Expanded(
                        child: Text(
                          metric.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant.withValues(
                              alpha: 0.7,
                            ),
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                    if (metric.change != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: metric.isPositive
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              metric.isPositive
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              size: 10,
                              color: metric.isPositive
                                  ? Colors.green
                                  : Colors.red,
                            ),
                            const Gap(2),
                            Text(
                              metric.change!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: metric.isPositive
                                    ? Colors.green
                                    : Colors.red,
                                fontWeight: FontWeight.w600,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static IconData _getIconData(String iconName) {
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

import 'package:equatable/equatable.dart';
import 'analytics_metric.dart';
import 'analytics_chart_data.dart';

class AnalyticsOverview extends Equatable {
  final List<AnalyticsMetric> metrics;
  final List<AnalyticsChartData> charts;
  final DateTime lastUpdated;
  final String period;

  const AnalyticsOverview({
    required this.metrics,
    required this.charts,
    required this.lastUpdated,
    required this.period,
  });

  factory AnalyticsOverview.fromJson(Map<String, dynamic> json) {
    return AnalyticsOverview(
      metrics: (json['metrics'] as List<dynamic>)
          .map((item) => AnalyticsMetric.fromJson(item as Map<String, dynamic>))
          .toList(),
      charts: (json['charts'] as List<dynamic>)
          .map((item) => AnalyticsChartData.fromJson(item as Map<String, dynamic>))
          .toList(),
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      period: json['period'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'metrics': metrics.map((metric) => metric.toJson()).toList(),
      'charts': charts.map((chart) => chart.toJson()).toList(),
      'lastUpdated': lastUpdated.toIso8601String(),
      'period': period,
    };
  }

  @override
  List<Object?> get props => [metrics, charts, lastUpdated, period];
}

import 'package:equatable/equatable.dart';

enum ChartType { line, bar, pie, area }

class ChartDataPoint extends Equatable {
  final String label;
  final double value;
  final String? color;
  final DateTime? date;
  final String? serviceType;

  const ChartDataPoint({
    required this.label,
    required this.value,
    this.color,
    this.date,
    this.serviceType,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label'] as String,
      value: (json['value'] as num? ?? 0).toDouble(),
      color: json['color'] as String?,
      date: json['date'] != null
          ? DateTime.parse(json['date'] as String)
          : null,
      serviceType: json['serviceType'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'value': value,
      'color': color,
      'date': date?.toIso8601String(),
      'serviceType': serviceType,
    };
  }

  @override
  List<Object?> get props => [label, value, color, date, serviceType];
}

class AnalyticsChartData extends Equatable {
  final String title;
  final ChartType type;
  final List<ChartDataPoint> data;
  final String? xAxisLabel;
  final String? yAxisLabel;
  final String? description;

  const AnalyticsChartData({
    required this.title,
    required this.type,
    required this.data,
    this.xAxisLabel,
    this.yAxisLabel,
    this.description,
  });

  factory AnalyticsChartData.fromJson(Map<String, dynamic> json) {
    return AnalyticsChartData(
      title: json['title'] as String,
      type: ChartType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => ChartType.bar,
      ),
      data: (json['data'] as List<dynamic>)
          .map((item) => ChartDataPoint.fromJson(item as Map<String, dynamic>))
          .toList(),
      xAxisLabel: json['xAxisLabel'] as String?,
      yAxisLabel: json['yAxisLabel'] as String?,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'type': type.name,
      'data': data.map((point) => point.toJson()).toList(),
      'xAxisLabel': xAxisLabel,
      'yAxisLabel': yAxisLabel,
      'description': description,
    };
  }

  @override
  List<Object?> get props => [
    title,
    type,
    data,
    xAxisLabel,
    yAxisLabel,
    description,
  ];
}

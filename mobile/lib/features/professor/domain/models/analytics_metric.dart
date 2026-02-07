import 'package:equatable/equatable.dart';

class AnalyticsMetric extends Equatable {
  final String title;
  final String value;
  final String? change;
  final String icon;
  final String color;
  final bool isPositive;
  final String? subtitle;

  const AnalyticsMetric({
    required this.title,
    required this.value,
    this.change,
    required this.icon,
    required this.color,
    this.isPositive = true,
    this.subtitle,
  });

  factory AnalyticsMetric.fromJson(Map<String, dynamic> json) {
    return AnalyticsMetric(
      title: json['title'] as String,
      value: json['value'] as String,
      change: json['change'] as String?,
      icon: json['icon'] as String,
      color: json['color'] as String,
      isPositive: json['isPositive'] as bool? ?? true,
      subtitle: json['subtitle'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'value': value,
      'change': change,
      'icon': icon,
      'color': color,
      'isPositive': isPositive,
      'subtitle': subtitle,
    };
  }

  @override
  List<Object?> get props => [
    title,
    value,
    change,
    icon,
    color,
    isPositive,
    subtitle,
  ];
}

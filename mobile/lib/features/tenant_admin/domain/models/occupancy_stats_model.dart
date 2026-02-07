class OccupancyStats {
  final double currentPercentage;
  final double previousPercentage;
  final String trend;

  OccupancyStats({
    required this.currentPercentage,
    required this.previousPercentage,
    required this.trend,
  });

  factory OccupancyStats.fromJson(Map<String, dynamic> json) {
    return OccupancyStats(
      currentPercentage: (json['currentPercentage'] as num).toDouble(),
      previousPercentage: (json['previousPercentage'] as num).toDouble(),
      trend: json['trend'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'currentPercentage': currentPercentage,
      'previousPercentage': previousPercentage,
      'trend': trend,
    };
  }
}

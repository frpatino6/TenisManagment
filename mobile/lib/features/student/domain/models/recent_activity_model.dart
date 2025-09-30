class RecentActivityModel {
  final String id;
  final String type; // 'booking', 'payment', 'service_request'
  final String title;
  final String description;
  final DateTime date;
  final String status;
  final String icon; // Icon name as string
  final String color; // Color name as string

  RecentActivityModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.date,
    required this.status,
    required this.icon,
    required this.color,
  });

  factory RecentActivityModel.fromJson(Map<String, dynamic> json) {
    return RecentActivityModel(
      id: json['id'] as String,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      date: DateTime.parse(json['date'] as String),
      status: json['status'] as String,
      icon: json['icon'] as String,
      color: json['color'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'title': title,
      'description': description,
      'date': date.toIso8601String(),
      'status': status,
      'icon': icon,
      'color': color,
    };
  }

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Ahora';
    } else if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} día${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return 'Hace $weeks semana${weeks > 1 ? 's' : ''}';
    } else {
      final months = (difference.inDays / 30).floor();
      return 'Hace $months mes${months > 1 ? 'es' : ''}';
    }
  }
}

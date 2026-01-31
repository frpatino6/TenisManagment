import 'package:equatable/equatable.dart';

enum RankingTrend { up, down, stable }

enum RankingType { elo, race }

/// Representa el ranking de un usuario en el sistema.
class UserRanking extends Equatable {
  final String userId;
  final String name;
  final String? avatarUrl;
  final int position;
  final double score;
  final RankingTrend trend;
  final bool isCurrentUser;

  String get formattedScore => score.toStringAsFixed(0);

  /// Crea una instancia de [UserRanking].
  const UserRanking({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.position,
    required this.score,
    this.trend = RankingTrend.stable,
    this.isCurrentUser = false,
  });

  /// Crea un [UserRanking] a partir de un JSON.
  factory UserRanking.fromJson(Map<String, dynamic> json) {
    return UserRanking(
      userId: json['userId'] as String,
      name: json['name'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      position: json['position'] as int,
      score: (json['score'] as num).toDouble(),
      trend: _parseTrend(json['trend'] as String?),
      isCurrentUser: json['isCurrentUser'] as bool? ?? false,
    );
  }

  /// Crea un [UserRanking] a partir de un JSON del backend.
  factory UserRanking.fromBackendJson(
    Map<String, dynamic> json, {
    required String currentUserId,
    bool isRace = false,
  }) {
    final userId = json['userId'] as String;
    return UserRanking(
      userId: userId,
      name: json['userName'] as String? ?? 'Usuario',
      avatarUrl: json['userAvatar'] as String?,
      position: json['position'] as int? ?? 0,
      score: (json[isRace ? 'monthlyRacePoints' : 'eloScore'] as num? ?? 0)
          .toDouble(),
      trend: RankingTrend.stable,
      isCurrentUser: userId == currentUserId,
    );
  }

  static RankingTrend _parseTrend(String? trend) {
    switch (trend) {
      case 'up':
        return RankingTrend.up;
      case 'down':
        return RankingTrend.down;
      default:
        return RankingTrend.stable;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'name': name,
      'avatarUrl': avatarUrl,
      'position': position,
      'score': score,
      'trend': trend.name,
      'isCurrentUser': isCurrentUser,
    };
  }

  UserRanking copyWith({
    String? userId,
    String? name,
    String? avatarUrl,
    int? position,
    double? score,
    RankingTrend? trend,
    bool? isCurrentUser,
  }) {
    return UserRanking(
      userId: userId ?? this.userId,
      name: name ?? this.name,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      position: position ?? this.position,
      score: score ?? this.score,
      trend: trend ?? this.trend,
      isCurrentUser: isCurrentUser ?? this.isCurrentUser,
    );
  }

  @override
  List<Object?> get props => [
    userId,
    name,
    avatarUrl,
    position,
    score,
    trend,
    isCurrentUser,
  ];
}

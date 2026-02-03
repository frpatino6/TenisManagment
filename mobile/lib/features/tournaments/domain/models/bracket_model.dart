/// Modelo de dominio para un bracket de torneo.
class BracketModel {
  final String id;
  final String tournamentId;
  final String categoryId;
  final List<BracketMatchModel> matches;
  final BracketStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const BracketModel({
    required this.id,
    required this.tournamentId,
    required this.categoryId,
    required this.matches,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory BracketModel.fromJson(Map<String, dynamic> json) {
    return BracketModel(
      id: json['id'] as String? ?? json['_id'] as String,
      tournamentId: json['tournamentId'] as String,
      categoryId: json['categoryId'] as String,
      matches: (json['matches'] as List<dynamic>)
          .map((e) => BracketMatchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: BracketStatus.fromString(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'matches': matches.map((e) => e.toJson()).toList(),
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Obtiene todos los matches de una ronda específica.
  List<BracketMatchModel> getMatchesByRound(int round) {
    return matches.where((m) => m.round == round).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
  }

  /// Obtiene el match de la final (round 1).
  BracketMatchModel? getFinalMatch() {
    return matches.where((m) => m.round == 1).firstOrNull;
  }

  /// Calcula el número total de rondas.
  int getTotalRounds() {
    if (matches.isEmpty) return 0;
    return matches.map((m) => m.round).reduce((a, b) => a > b ? a : b);
  }

  /// Obtiene el campeón si el bracket está completo.
  String? getChampion() {
    final finalMatch = getFinalMatch();
    return finalMatch?.winnerId;
  }

  /// Verifica si el bracket está completo.
  bool get isCompleted => status == BracketStatus.completed;
}

/// Estado de un bracket.
enum BracketStatus {
  pending('PENDING'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED');

  final String value;
  const BracketStatus(this.value);

  static BracketStatus fromString(String value) {
    return BracketStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => BracketStatus.pending,
    );
  }
}

/// Modelo para un match individual dentro del bracket.
class BracketMatchModel {
  final String id;
  final int round;
  final int position;
  final String? player1Id;
  final String? player1Name;
  final String? player2Id;
  final String? player2Name;
  final String? winnerId;
  final String? winnerName;
  final String? score;
  final String? nextMatchId;
  final DateTime? matchDate;

  const BracketMatchModel({
    required this.id,
    required this.round,
    required this.position,
    this.player1Id,
    this.player1Name,
    this.player2Id,
    this.player2Name,
    this.winnerId,
    this.winnerName,
    this.score,
    this.nextMatchId,
    this.matchDate,
  });

  factory BracketMatchModel.fromJson(Map<String, dynamic> json) {
    return BracketMatchModel(
      id: json['id'] as String,
      round: json['round'] as int,
      position: json['position'] as int,
      player1Id: json['player1Id'] as String?,
      player1Name: json['player1Name'] as String?,
      player2Id: json['player2Id'] as String?,
      player2Name: json['player2Name'] as String?,
      winnerId: json['winnerId'] as String?,
      winnerName: json['winnerName'] as String?,
      score: json['score'] as String?,
      nextMatchId: json['nextMatchId'] as String?,
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'round': round,
      'position': position,
      'player1Id': player1Id,
      'player1Name': player1Name,
      'player2Id': player2Id,
      'player2Name': player2Name,
      'winnerId': winnerId,
      'winnerName': winnerName,
      'score': score,
      'nextMatchId': nextMatchId,
      'matchDate': matchDate?.toIso8601String(),
    };
  }

  BracketMatchModel copyWith({
    String? id,
    int? round,
    int? position,
    String? player1Id,
    String? player1Name,
    String? player2Id,
    String? player2Name,
    String? winnerId,
    String? winnerName,
    String? score,
    String? nextMatchId,
    DateTime? matchDate,
  }) {
    return BracketMatchModel(
      id: id ?? this.id,
      round: round ?? this.round,
      position: position ?? this.position,
      player1Id: player1Id ?? this.player1Id,
      player1Name: player1Name ?? this.player1Name,
      player2Id: player2Id ?? this.player2Id,
      player2Name: player2Name ?? this.player2Name,
      winnerId: winnerId ?? this.winnerId,
      winnerName: winnerName ?? this.winnerName,
      score: score ?? this.score,
      nextMatchId: nextMatchId ?? this.nextMatchId,
      matchDate: matchDate ?? this.matchDate,
    );
  }

  /// Verifica si el match tiene un BYE (un jugador falta).
  bool get hasBye => player1Id == null || player2Id == null;

  /// Verifica si el match está completo (tiene ganador).
  bool get isCompleted => winnerId != null;

  /// Verifica si el match está pendiente.
  bool get isPending => !isCompleted && player1Id != null && player2Id != null;

  /// Verifica si un usuario específico está en este match.
  bool hasPlayer(String userId) {
    return player1Id == userId || player2Id == userId;
  }

  /// Obtiene el ID del perdedor.
  String? get loserId {
    if (winnerId == null) return null;
    if (winnerId == player1Id) return player2Id;
    if (winnerId == player2Id) return player1Id;
    return null;
  }
}

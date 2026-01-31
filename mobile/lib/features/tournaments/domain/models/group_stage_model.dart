/// Modelo de dominio para la fase de grupos de un torneo.
class GroupStageModel {
  final String? id;
  final String tournamentId;
  final String categoryId;
  final List<GroupModel> groups;
  final GroupStageStatus status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const GroupStageModel({
    this.id,
    required this.tournamentId,
    required this.categoryId,
    required this.groups,
    required this.status,
    this.createdAt,
    this.updatedAt,
  });

  factory GroupStageModel.fromJson(Map<String, dynamic> json) {
    return GroupStageModel(
      id: json['id'] as String? ?? json['_id'] as String?,
      tournamentId: json['tournamentId'] as String,
      categoryId: json['categoryId'] as String,
      groups: ((json['groups'] ?? []) as List<dynamic>)
          .map((e) => GroupModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      status: GroupStageStatus.fromString(json['status'] as String),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'tournamentId': tournamentId,
      'categoryId': categoryId,
      'groups': groups.map((e) => e.toJson()).toList(),
      'status': status.value,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}

/// Modelo para un grupo individual dentro de la fase de grupos.
class GroupModel {
  final String id;
  final String name;
  final int seed;
  final List<String> participants;
  final List<GroupStageMatchModel> matches;
  final List<GroupStandingModel> standings;

  const GroupModel({
    required this.id,
    required this.name,
    required this.seed,
    required this.participants,
    required this.matches,
    required this.standings,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      seed: json['seed'] as int,
      participants: (json['participants'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      matches: ((json['matches'] ?? []) as List<dynamic>)
          .map((e) => GroupStageMatchModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      standings: ((json['standings'] ?? []) as List<dynamic>)
          .map((e) => GroupStandingModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'seed': seed,
      'participants': participants,
      'matches': matches.map((e) => e.toJson()).toList(),
      'standings': standings.map((e) => e.toJson()).toList(),
    };
  }
}

/// Modelo para un partido dentro de un grupo.
class GroupStageMatchModel {
  final String id;
  final String groupId;
  final String player1Id;
  final String? player1Name;
  final double? player1Elo;
  final String player2Id;
  final String? player2Name;
  final double? player2Elo;
  final String? winnerId;
  final String? score;
  final DateTime? matchDate;
  final int? round;

  const GroupStageMatchModel({
    required this.id,
    required this.groupId,
    required this.player1Id,
    this.player1Name,
    this.player1Elo,
    required this.player2Id,
    this.player2Name,
    this.player2Elo,
    this.winnerId,
    this.score,
    this.matchDate,
    this.round,
  });

  factory GroupStageMatchModel.fromJson(Map<String, dynamic> json) {
    return GroupStageMatchModel(
      id: json['id'] as String,
      groupId: json['groupId'] as String,
      player1Id: json['player1Id'] as String,
      player1Name: json['player1Name'] as String?,
      player1Elo: (json['player1Elo'] as num?)?.toDouble(),
      player2Id: json['player2Id'] as String,
      player2Name: json['player2Name'] as String?,
      player2Elo: (json['player2Elo'] as num?)?.toDouble(),
      winnerId: json['winnerId'] as String?,
      score: json['score'] as String?,
      matchDate: json['matchDate'] != null
          ? DateTime.parse(json['matchDate'] as String)
          : null,
      round: json['round'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'groupId': groupId,
      'player1Id': player1Id,
      if (player1Name != null) 'player1Name': player1Name,
      if (player1Elo != null) 'player1Elo': player1Elo,
      'player2Id': player2Id,
      if (player2Name != null) 'player2Name': player2Name,
      if (player2Elo != null) 'player2Elo': player2Elo,
      if (winnerId != null) 'winnerId': winnerId,
      if (score != null) 'score': score,
      if (matchDate != null) 'matchDate': matchDate!.toIso8601String(),
      if (round != null) 'round': round,
    };
  }

  bool get isCompleted => winnerId != null;
}

/// Modelo para la clasificación de un jugador en un grupo.
class GroupStandingModel {
  final String playerId;
  final String? playerName;
  final double? playerElo;
  final int position;
  final int matchesPlayed;
  final int wins;
  final int draws;
  final int losses;
  final int points;
  final int setsWon;
  final int setsLost;
  final int gamesWon;
  final int gamesLost;
  final int setDifference;
  final int gameDifference;
  final bool qualifiedForKnockout;

  const GroupStandingModel({
    required this.playerId,
    this.playerName,
    this.playerElo,
    required this.position,
    required this.matchesPlayed,
    required this.wins,
    required this.draws,
    required this.losses,
    required this.points,
    required this.setsWon,
    required this.setsLost,
    required this.gamesWon,
    required this.gamesLost,
    required this.setDifference,
    required this.gameDifference,
    required this.qualifiedForKnockout,
  });

  factory GroupStandingModel.fromJson(Map<String, dynamic> json) {
    return GroupStandingModel(
      playerId: json['playerId'] as String,
      playerName: json['playerName'] as String?,
      playerElo: (json['playerElo'] as num?)?.toDouble(),
      position: json['position'] as int,
      matchesPlayed: json['matchesPlayed'] as int,
      wins: json['wins'] as int,
      draws: json['draws'] as int,
      losses: json['losses'] as int,
      points: json['points'] as int,
      setsWon: json['setsWon'] as int,
      setsLost: json['setsLost'] as int,
      gamesWon: json['gamesWon'] as int,
      gamesLost: json['gamesLost'] as int,
      setDifference: json['setDifference'] as int,
      gameDifference: json['gameDifference'] as int,
      qualifiedForKnockout: json['qualifiedForKnockout'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'playerId': playerId,
      if (playerName != null) 'playerName': playerName,
      if (playerElo != null) 'playerElo': playerElo,
      'position': position,
      'matchesPlayed': matchesPlayed,
      'wins': wins,
      'draws': draws,
      'losses': losses,
      'points': points,
      'setsWon': setsWon,
      'setsLost': setsLost,
      'gamesWon': gamesWon,
      'gamesLost': gamesLost,
      'setDifference': setDifference,
      'gameDifference': gameDifference,
      'qualifiedForKnockout': qualifiedForKnockout,
    };
  }
}

/// Estados posibles de la fase de grupos.
enum GroupStageStatus {
  draft('DRAFT'),
  locked('LOCKED'),
  inProgress('IN_PROGRESS'),
  completed('COMPLETED');

  final String value;
  const GroupStageStatus(this.value);

  static GroupStageStatus fromString(String value) {
    return GroupStageStatus.values.firstWhere(
      (e) => e.value == value,
      orElse: () => GroupStageStatus.draft,
    );
  }
}

import 'package:equatable/equatable.dart';

class MatchModel extends Equatable {
  final String? id;
  final String winnerId;
  final String loserId;
  final String score;
  final DateTime date;
  final bool isTournament;
  final bool isOffPeak;
  final bool isMatchmakingChallenge;

  const MatchModel({
    this.id,
    required this.winnerId,
    required this.loserId,
    required this.score,
    required this.date,
    this.isTournament = false,
    this.isOffPeak = false,
    this.isMatchmakingChallenge = false,
  });

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'] as String?,
      winnerId: json['winnerId'] as String,
      loserId: json['loserId'] as String,
      score: json['score'] as String,
      date: DateTime.parse(json['date'] as String),
      isTournament: json['isTournament'] as bool? ?? false,
      isOffPeak: json['isOffPeak'] as bool? ?? false,
      isMatchmakingChallenge: json['isMatchmakingChallenge'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'winnerId': winnerId,
      'loserId': loserId,
      'score': score,
      'isTournament': isTournament,
      'isOffPeak': isOffPeak,
      'isMatchmakingChallenge': isMatchmakingChallenge,
    };
  }

  @override
  List<Object?> get props => [
    id,
    winnerId,
    loserId,
    score,
    date,
    isTournament,
    isOffPeak,
    isMatchmakingChallenge,
  ];
}

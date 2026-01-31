import '../models/match_model.dart';

/// Repositorio para la gestión de partidos.
abstract class MatchRepository {
  /// Registra el resultado de un partido.
  Future<void> recordMatchResult({
    required String winnerId,
    required String loserId,
    required String score,
    bool isTournament = false,
    bool isOffPeak = false,
    bool isMatchmakingChallenge = false,
  });

  /// Obtiene la lista de partidos recientes.
  Future<List<MatchModel>> getRecentMatches();
}

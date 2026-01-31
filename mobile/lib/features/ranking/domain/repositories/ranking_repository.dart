import '../../domain/models/user_ranking.dart';

/// Interfaz del repositorio de ranking.
abstract class RankingRepository {
  /// Obtiene el listado de ranking por ELO.
  Future<List<UserRanking>> getEloRankings();

  /// Obtiene el listado de ranking mensual (The Race).
  Future<List<UserRanking>> getRaceRankings();
}

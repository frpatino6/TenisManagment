import '../../domain/repositories/ranking_repository.dart';
import '../../domain/models/user_ranking.dart';

class GetRankingsUseCase {
  final RankingRepository _repository;

  GetRankingsUseCase(this._repository);

  Future<List<UserRanking>> getElo() => _repository.getEloRankings();
  Future<List<UserRanking>> getRace() => _repository.getRaceRankings();
}

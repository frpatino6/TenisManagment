import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../domain/models/user_ranking.dart';
import '../../domain/repositories/ranking_repository.dart';
import '../../infrastructure/repositories/mock_ranking_repository.dart';
import '../../application/use_cases/get_rankings_use_case.dart';

part 'ranking_providers.g.dart';

@riverpod
RankingRepository rankingRepository(Ref ref) {
  // Cambio temporal a Mock para visualización en UI
  return MockRankingRepository();
}

@riverpod
GetRankingsUseCase getRankingsUseCase(Ref ref) {
  final repository = ref.watch(rankingRepositoryProvider);
  return GetRankingsUseCase(repository);
}

@riverpod
class EloRanking extends _$EloRanking {
  @override
  Future<List<UserRanking>> build() async {
    final useCase = ref.watch(getRankingsUseCaseProvider);
    return useCase.getElo();
  }
}

@riverpod
class RaceRanking extends _$RaceRanking {
  @override
  Future<List<UserRanking>> build() async {
    final useCase = ref.watch(getRankingsUseCaseProvider);
    return useCase.getRace();
  }
}

@riverpod
class CurrentUserRanking extends _$CurrentUserRanking {
  @override
  UserRanking? build(RankingType type) {
    final rankingAsync = type == RankingType.elo
        ? ref.watch(eloRankingProvider)
        : ref.watch(raceRankingProvider);

    return rankingAsync.when(
      data: (list) => list.where((u) => u.isCurrentUser).firstOrNull,
      loading: () => null,
      error: (e, s) => null,
    );
  }
}

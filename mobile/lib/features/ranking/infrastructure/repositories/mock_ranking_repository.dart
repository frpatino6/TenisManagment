import '../../domain/models/user_ranking.dart';
import '../../domain/repositories/ranking_repository.dart';

class MockRankingRepository implements RankingRepository {
  @override
  Future<List<UserRanking>> getEloRankings() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const UserRanking(
        userId: '1',
        name: 'Carlos Alcaraz',
        position: 1,
        score: 2850.0,
        trend: RankingTrend.stable,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Carlos',
      ),
      const UserRanking(
        userId: '2',
        name: 'Jannik Sinner',
        position: 2,
        score: 2720.0,
        trend: RankingTrend.up,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jannik',
      ),
      const UserRanking(
        userId: '3',
        name: 'Novak Djokovic',
        position: 3,
        score: 2680.0,
        trend: RankingTrend.down,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Novak',
      ),
      const UserRanking(
        userId: '4',
        name: 'Daniil Medvedev',
        position: 4,
        score: 2450.0,
        trend: RankingTrend.stable,
      ),
      const UserRanking(
        userId: '5',
        name: 'Alexander Zverev',
        position: 5,
        score: 2310.0,
        trend: RankingTrend.up,
      ),
      const UserRanking(
        userId: 'currentUser',
        name: 'Yo (Fernando)',
        position: 12,
        score: 1850.0,
        trend: RankingTrend.stable,
        isCurrentUser: true,
      ),
    ];
  }

  @override
  Future<List<UserRanking>> getRaceRankings() async {
    await Future.delayed(const Duration(seconds: 1));
    return [
      const UserRanking(
        userId: '2',
        name: 'Jannik Sinner',
        position: 1,
        score: 450.0,
        trend: RankingTrend.up,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Jannik',
      ),
      const UserRanking(
        userId: '1',
        name: 'Carlos Alcaraz',
        position: 2,
        score: 420.0,
        trend: RankingTrend.down,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Carlos',
      ),
      const UserRanking(
        userId: '5',
        name: 'Alexander Zverev',
        position: 3,
        score: 380.0,
        trend: RankingTrend.up,
        avatarUrl: 'https://api.dicebear.com/7.x/avataaars/svg?seed=Zverev',
      ),
      const UserRanking(
        userId: '3',
        name: 'Novak Djokovic',
        position: 4,
        score: 310.0,
        trend: RankingTrend.stable,
      ),
      const UserRanking(
        userId: 'currentUser',
        name: 'Yo (Fernando)',
        position: 8,
        score: 150.0,
        trend: RankingTrend.up,
        isCurrentUser: true,
      ),
    ];
  }
}

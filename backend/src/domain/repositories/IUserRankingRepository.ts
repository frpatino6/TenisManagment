import { UserRanking, UserRankingWithDetails } from '../entities/UserRanking';

export interface IUserRankingRepository {
    findByUserAndTenant(tenantId: string, userId: string): Promise<UserRanking | null>;
    create(ranking: UserRanking): Promise<UserRanking>;
    update(id: string, ranking: Partial<UserRanking>): Promise<UserRanking | null>;
    getTopByElo(tenantId: string, limit: number): Promise<UserRanking[]>;
    getRankingsWithUsers(tenantId: string, type: 'elo' | 'race', limit: number): Promise<UserRankingWithDetails[]>;
    resetMonthlyRace(tenantId?: string): Promise<void>;
}

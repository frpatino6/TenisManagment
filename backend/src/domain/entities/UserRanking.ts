export interface UserRanking {
    id?: string;
    userId: string;
    tenantId: string;
    eloScore: number;
    monthlyRacePoints: number;
    totalMatches: number;
    winRate: number;
    lastResetDate: Date;
    createdAt?: Date;
    updatedAt?: Date;
}

export interface UserRankingWithDetails extends UserRanking {
    userName: string;
    userAvatar?: string;
    position?: number;
}

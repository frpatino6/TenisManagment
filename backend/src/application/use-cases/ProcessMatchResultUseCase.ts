import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { Logger } from '../../infrastructure/services/Logger';
import { UserRanking } from '../../domain/entities/UserRanking';

export interface MatchResultData {
    tenantId: string;
    winnerId: string;
    loserId: string;
    isTournament: boolean;
    isOffPeak?: boolean;
    isMatchmakingChallenge?: boolean;
}

export interface RankingUpdateResponse {
    elo: { prev: number; new: number; gain: number };
    race: { prev: number; new: number; gain: number; details: string };
}

export interface MatchProcessResponse {
    winner: RankingUpdateResponse;
    loser: RankingUpdateResponse;
}

export class ProcessMatchResultUseCase {
    private readonly logger = new Logger({ service: 'ProcessMatchResultUseCase' });
    private readonly K_FACTOR = 32;

    constructor(private readonly rankingRepository: IUserRankingRepository) { }

    public async execute(matchData: MatchResultData): Promise<MatchProcessResponse> {
        this.logger.info('Procesando resultado de partido', { matchData });

        try {
            const { tenantId, winnerId, loserId } = matchData;

            const [winnerRanking, loserRanking] = await Promise.all([
                this.getOrCreateRanking(tenantId, winnerId),
                this.getOrCreateRanking(tenantId, loserId),
            ]);

            const eloResults = this.calculateElo(winnerRanking.eloScore, loserRanking.eloScore);
            const winnerRace = this.calculateRacePoints(matchData, true);
            const loserRace = this.calculateRacePoints(matchData, false);

            const updatedWinner = await this.updateRanking(winnerRanking, {
                eloGain: eloResults.winnerGain,
                raceGain: winnerRace.total,
                isWin: true,
            });

            const updatedLoser = await this.updateRanking(loserRanking, {
                eloGain: eloResults.loserGain,
                raceGain: loserRace.total,
                isWin: false,
            });

            if (!updatedWinner || !updatedLoser) {
                throw new Error('Failed to update rankings');
            }

            return {
                winner: {
                    elo: { prev: winnerRanking.eloScore, new: updatedWinner.eloScore, gain: eloResults.winnerGain },
                    race: {
                        prev: winnerRanking.monthlyRacePoints,
                        new: updatedWinner.monthlyRacePoints,
                        gain: winnerRace.total,
                        details: winnerRace.breakdown
                    }
                },
                loser: {
                    elo: { prev: loserRanking.eloScore, new: updatedLoser.eloScore, gain: eloResults.loserGain },
                    race: {
                        prev: loserRanking.monthlyRacePoints,
                        new: updatedLoser.monthlyRacePoints,
                        gain: loserRace.total,
                        details: loserRace.breakdown
                    }
                }
            };
        } catch (error) {
            this.logger.error('Error procesando resultado de partido', { error, matchData });
            throw error;
        }
    }

    private async getOrCreateRanking(tenantId: string, userId: string): Promise<UserRanking> {
        let ranking = await this.rankingRepository.findByUserAndTenant(tenantId, userId);

        if (!ranking) {
            ranking = await this.rankingRepository.create({
                tenantId,
                userId,
                eloScore: 1200,
                monthlyRacePoints: 0,
                totalMatches: 0,
                winRate: 0,
                lastResetDate: new Date()
            });
        }

        return ranking;
    }

    private calculateElo(winnerElo: number, loserElo: number) {
        const expectationWinner = 1 / (1 + Math.pow(10, (loserElo - winnerElo) / 400));
        const expectationLoser = 1 / (1 + Math.pow(10, (winnerElo - loserElo) / 400));

        const winnerGain = Math.round(this.K_FACTOR * (1 - expectationWinner));
        const loserGain = Math.round(this.K_FACTOR * (0 - expectationLoser));

        return { winnerGain, loserGain };
    }

    private calculateRacePoints(matchData: MatchResultData, isWinner: boolean) {
        const Pbase = 10;
        let Pbonus = 0;

        if (isWinner) Pbonus += 15;
        if (matchData.isOffPeak) Pbonus += 5;
        if (matchData.isMatchmakingChallenge) Pbonus += 20;

        const multiplier = matchData.isTournament ? 2.5 : 1.0;
        const total = Math.round((Pbase + Pbonus) * multiplier);

        let breakdown = `(Base ${Pbase}`;
        if (isWinner) breakdown += ' + Win 15';
        if (matchData.isOffPeak) breakdown += ' + OffPeak 5';
        if (matchData.isMatchmakingChallenge) breakdown += ' + Challenge 20';
        breakdown += `) * ${matchData.isTournament ? 'Tournament 2.5' : 'Friendly 1.0'}`;

        return { total, breakdown };
    }

    private async updateRanking(ranking: UserRanking, data: { eloGain: number, raceGain: number, isWin: boolean }): Promise<UserRanking | null> {
        if (!ranking.id) return null;

        const totalMatches = ranking.totalMatches + 1;
        const wins = (ranking.winRate * ranking.totalMatches / 100) + (data.isWin ? 1 : 0);
        const winRate = (wins / totalMatches) * 100;

        return this.rankingRepository.update(ranking.id, {
            eloScore: ranking.eloScore + data.eloGain,
            monthlyRacePoints: ranking.monthlyRacePoints + data.raceGain,
            totalMatches: totalMatches,
            winRate: Math.round(winRate * 100) / 100
        });
    }
}

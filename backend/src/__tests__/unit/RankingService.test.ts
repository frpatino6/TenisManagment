import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { RankingService } from '../../application/services/RankingService';
import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { UserRanking } from '../../domain/entities/UserRanking';

describe('RankingService', () => {
    let rankingService: RankingService;
    let mockRepo: jest.Mocked<IUserRankingRepository>;
    const tenantId = 'tenant-123';

    beforeEach(() => {
        mockRepo = {
            findByUserAndTenant: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
            getTopByElo: jest.fn(),
            getRankingsWithUsers: jest.fn(),
            resetMonthlyRace: jest.fn(),
        } as any;

        rankingService = new RankingService(mockRepo);
    });

    describe('getRankings', () => {
        it('should return rankings with user details from repository', async () => {
            const expected = [
                { id: '1', userId: 'u1', userName: 'Player 1', eloScore: 1500, position: 1 } as any
            ];
            mockRepo.getRankingsWithUsers.mockResolvedValue(expected);

            const result = await rankingService.getRankings(tenantId, 'elo');

            expect(result).toEqual(expected);
            expect(mockRepo.getRankingsWithUsers).toHaveBeenCalledWith(tenantId, 'elo', 50);
        });
    });

    describe('processMatchResult', () => {
        it('should update ELO correctly for equal players', async () => {
            const winnerId = 'winner-1';
            const loserId = 'loser-1';

            const winnerRanking: UserRanking = {
                id: 'r1', userId: winnerId, tenantId, eloScore: 1200,
                monthlyRacePoints: 0, totalMatches: 0, winRate: 0, lastResetDate: new Date()
            };
            const loserRanking: UserRanking = {
                id: 'r2', userId: loserId, tenantId, eloScore: 1200,
                monthlyRacePoints: 0, totalMatches: 0, winRate: 0, lastResetDate: new Date()
            };

            mockRepo.findByUserAndTenant
                .mockResolvedValueOnce(winnerRanking)
                .mockResolvedValueOnce(loserRanking);

            mockRepo.update.mockImplementation((id, data) => Promise.resolve({
                ...(id === 'r1' ? winnerRanking : loserRanking),
                ...data
            } as UserRanking));

            const result = await rankingService.processMatchResult({
                tenantId,
                winnerId,
                loserId,
                isTournament: false,
            });

            expect(result.winner.elo.gain).toBe(16);
            expect(result.loser.elo.gain).toBe(-16);
            expect(result.winner.elo.new).toBe(1216);
            expect(result.loser.elo.new).toBe(1184);
        });

        it('should calculate The Race points with multipliers and bonus', async () => {
            const winnerId = 'winner-2';
            const loserId = 'loser-2';

            mockRepo.findByUserAndTenant.mockImplementation((t, u) => Promise.resolve({
                id: u === winnerId ? 'rw' : 'rl',
                userId: u,
                tenantId: t,
                eloScore: 1200,
                monthlyRacePoints: 100,
                totalMatches: 10,
                winRate: 50,
                lastResetDate: new Date()
            } as UserRanking));

            mockRepo.update.mockImplementation((id, data) => Promise.resolve({
                id,
                eloScore: 1200,
                monthlyRacePoints: 100 + (data.monthlyRacePoints ?? 0),
                totalMatches: 11,
                winRate: 50,
            } as any));

            const result = await rankingService.processMatchResult({
                tenantId,
                winnerId,
                loserId,
                isTournament: true, // Multiplier 2.5
                isOffPeak: true,    // Bonus +5
            });

            // Winner: (10 Base + 15 Win + 5 OffPeak) * 2.5 = 30 * 2.5 = 75
            // Loser: (10 Base + 5 OffPeak) * 2.5 = 15 * 2.5 = 37.5 -> Math.round(37.5) = 38
            expect(result.winner.race.gain).toBe(75);
            expect(result.loser.race.gain).toBe(38);
            expect(result.winner.race.details).toContain('Base 10 + Win 15 + OffPeak 5');
            expect(result.winner.race.details).toContain('Tournament 2.5');
        });
    });

    describe('getHeadsOfSeries', () => {
        it('should return top N players by ELO from repository', async () => {
            const expectedRankings: UserRanking[] = [
                { id: '1', userId: 'u1', tenantId, eloScore: 1500 } as any,
                { id: '2', userId: 'u2', tenantId, eloScore: 1400 } as any,
            ];

            mockRepo.getTopByElo.mockResolvedValue(expectedRankings);

            const result = await rankingService.getHeadsOfSeries(tenantId, 2);
            expect(result).toEqual(expectedRankings);
            expect(mockRepo.getTopByElo).toHaveBeenCalledWith(tenantId, 2);
        });
    });

    describe('resetMonthlyRace', () => {
        it('should call repository reset', async () => {
            await rankingService.resetMonthlyRace(tenantId);
            expect(mockRepo.resetMonthlyRace).toHaveBeenCalledWith(tenantId);
        });
    });
});


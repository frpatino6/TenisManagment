import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { ProcessMatchResultUseCase, MatchResultData } from '../../application/use-cases/ProcessMatchResultUseCase';
import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { UserRanking } from '../../domain/entities/UserRanking';

// Mock Logger
jest.mock('../../infrastructure/services/Logger', () => {
    return {
        Logger: jest.fn().mockImplementation(() => ({
            info: jest.fn(),
            error: jest.fn(),
        })),
    };
});

describe('ProcessMatchResultUseCase', () => {
    let useCase: ProcessMatchResultUseCase;
    let mockRankingRepository: jest.Mocked<IUserRankingRepository>;

    const tenantId = 'tenant-1';
    const winnerId = 'u1';
    const loserId = 'u2';

    const baseRanking: UserRanking = {
        id: 'r1',
        tenantId,
        userId: winnerId,
        eloScore: 1200,
        monthlyRacePoints: 0,
        totalMatches: 0,
        winRate: 0,
        lastResetDate: new Date()
    };

    beforeEach(() => {
        mockRankingRepository = {
            findByUserAndTenant: jest.fn(),
            create: jest.fn(),
            update: jest.fn(),
        } as any;

        useCase = new ProcessMatchResultUseCase(mockRankingRepository);
    });

    it('should process match result and update rankings', async () => {
        // Setup initial rankings
        const winnerRanking = { ...baseRanking, userId: winnerId, id: 'rw' };
        const loserRanking = { ...baseRanking, userId: loserId, id: 'rl' };

        mockRankingRepository.findByUserAndTenant.mockImplementation(async (tid, uid) => {
            if (uid === winnerId) return winnerRanking;
            if (uid === loserId) return loserRanking;
            return null;
        });

        // Mock updates returning updated objects
        mockRankingRepository.update.mockImplementation(async (id, data: any) => {
            if (id === 'rw') return { ...winnerRanking, ...data };
            if (id === 'rl') return { ...loserRanking, ...data };
            return null;
        });

        const matchData: MatchResultData = {
            tenantId,
            winnerId,
            loserId,
            isTournament: false,
            isOffPeak: false
        };

        const result = await useCase.execute(matchData);

        expect(mockRankingRepository.findByUserAndTenant).toHaveBeenCalledTimes(2);
        expect(mockRankingRepository.update).toHaveBeenCalledTimes(2);

        // Verify ELO changes (both start at 1200, K=32)
        // Expected gain/loss around 16 points for equal ELO
        expect(result.winner.elo.gain).toBeGreaterThan(0);
        expect(result.loser.elo.gain).toBeLessThan(0);

        // Verify Race points
        // Base 10 + Win 15 * 1.0 = 25 for winner
        expect(result.winner.race.gain).toBe(25);
        // Base 10 * 1.0 = 10 for loser
        expect(result.loser.race.gain).toBe(10);
    });

    it('should create ranking if not exists', async () => {
        mockRankingRepository.findByUserAndTenant.mockResolvedValue(null);
        mockRankingRepository.create.mockResolvedValue({ ...baseRanking });
        mockRankingRepository.update.mockResolvedValue({ ...baseRanking });

        const matchData: MatchResultData = {
            tenantId,
            winnerId,
            loserId,
            isTournament: false
        };

        await useCase.execute(matchData);

        expect(mockRankingRepository.create).toHaveBeenCalledTimes(2);
    });

    it('should apply tournament multiplier', async () => {
        const winnerRanking = { ...baseRanking, userId: winnerId, id: 'rw' };
        const loserRanking = { ...baseRanking, userId: loserId, id: 'rl' };

        mockRankingRepository.findByUserAndTenant.mockResolvedValueOnce(winnerRanking).mockResolvedValueOnce(loserRanking);
        mockRankingRepository.update.mockImplementation(async (id, data: any) => ({ ...winnerRanking, ...data })); // Simplified return

        const matchData: MatchResultData = {
            tenantId,
            winnerId,
            loserId,
            isTournament: true // Multiplier 2.5
        };

        const result = await useCase.execute(matchData);

        // Winner: (10 + 15) * 2.5 = 62.5 -> round 63? or 62? Math.round(25 * 2.5) = Math.round(62.5) = 63
        expect(result.winner.race.gain).toBe(63);
    });
});

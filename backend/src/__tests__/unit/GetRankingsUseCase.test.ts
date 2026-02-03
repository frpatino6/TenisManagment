import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { GetRankingsUseCase } from '../../application/use-cases/GetRankingsUseCase';
import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';

// Mock Logger
jest.mock('../../infrastructure/services/Logger', () => {
    return {
        Logger: jest.fn().mockImplementation(() => ({
            info: jest.fn(),
            error: jest.fn(),
        })),
    };
});

describe('GetRankingsUseCase', () => {
    let useCase: GetRankingsUseCase;
    let mockRankingRepository: jest.Mocked<IUserRankingRepository>;

    const tenantId = 'tenant-1';

    beforeEach(() => {
        mockRankingRepository = {
            getRankingsWithUsers: jest.fn(),
            findByUser: jest.fn(),
            save: jest.fn(),
            updateRacePoints: jest.fn(),
            resetRacePoints: jest.fn(),
        } as any; // Using any for partial mock of complex interface if needed

        useCase = new GetRankingsUseCase(mockRankingRepository);
    });

    it('should get rankings successfully', async () => {
        const expectedRankings = [{ userId: 'u1', points: 100 }, { userId: 'u2', points: 90 }] as any;
        mockRankingRepository.getRankingsWithUsers.mockResolvedValue(expectedRankings);

        const result = await useCase.execute(tenantId, 'elo');

        expect(mockRankingRepository.getRankingsWithUsers).toHaveBeenCalledWith(tenantId, 'elo', 50);
        expect(result).toEqual(expectedRankings);
    });

    it('should respect limit parameter', async () => {
        mockRankingRepository.getRankingsWithUsers.mockResolvedValue([]);

        await useCase.execute(tenantId, 'race', 10);

        expect(mockRankingRepository.getRankingsWithUsers).toHaveBeenCalledWith(tenantId, 'race', 10);
    });

    it('should propagate errors', async () => {
        const error = new Error('DB Error');
        mockRankingRepository.getRankingsWithUsers.mockRejectedValue(error);

        await expect(useCase.execute(tenantId, 'elo')).rejects.toThrow(error);
    });
});

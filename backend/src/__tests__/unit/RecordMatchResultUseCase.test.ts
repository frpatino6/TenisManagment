import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { RecordMatchResultUseCase, RecordMatchInput } from '../../application/use-cases/RecordMatchResultUseCase';
import { IMatchRepository } from '../../domain/repositories/IMatchRepository';
import { RankingService } from '../../application/services/RankingService';
import { Match } from '../../domain/entities/Match';

describe('RecordMatchResultUseCase', () => {
    let useCase: RecordMatchResultUseCase;
    let mockMatchRepo: jest.Mocked<IMatchRepository>;
    let mockRankingService: jest.Mocked<RankingService>;

    const tenantId = 'tenant-1';
    const winnerId = 'w-1';
    const loserId = 'l-1';

    beforeEach(() => {
        mockMatchRepo = {
            save: jest.fn(),
            findById: jest.fn(),
            findByTenant: jest.fn(),
            findByUser: jest.fn(),
        } as any;

        mockRankingService = {
            processMatchResult: jest.fn(),
        } as any;

        useCase = new RecordMatchResultUseCase(mockMatchRepo, mockRankingService);
    });

    it('should save match and call ranking service', async () => {
        const input: RecordMatchInput = {
            tenantId,
            winnerId,
            loserId,
            score: '6-0, 6-0',
            isTournament: false,
            isOffPeak: false
        };

        const expectedMatch: Match = { ...input, id: 'm-1', date: new Date() };
        const expectedRankingResponse = {
            winner: { elo: { prev: 1200, new: 1216, gain: 16 }, race: { prev: 0, new: 10, gain: 10, details: '' } },
            loser: { elo: { prev: 1200, new: 1184, gain: -16 }, race: { prev: 0, new: 5, gain: 5, details: '' } },
        };

        mockMatchRepo.save.mockResolvedValue(expectedMatch);
        mockRankingService.processMatchResult.mockResolvedValue(expectedRankingResponse);

        const result = await useCase.execute(input);

        expect(mockMatchRepo.save).toHaveBeenCalled();
        expect(mockRankingService.processMatchResult).toHaveBeenCalledWith({
            tenantId,
            winnerId,
            loserId,
            isTournament: false,
            isOffPeak: false,
            isMatchmakingChallenge: undefined
        });
        expect(result.match).toEqual(expectedMatch);
        expect(result.rankingChanges).toEqual(expectedRankingResponse);
    });
});

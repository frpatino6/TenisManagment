import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { RecordTournamentMatchResultUseCase } from '../../application/use-cases/RecordTournamentMatchResultUseCase';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { RankingService } from '../../application/services/RankingService';
import { Bracket, BracketMatch } from '../../domain/entities/Bracket';
import { Tournament } from '../../domain/entities/Tournament';

describe('RecordTournamentMatchResultUseCase', () => {
    let useCase: RecordTournamentMatchResultUseCase;
    let mockBracketRepository: jest.Mocked<IBracketRepository>;
    let mockTournamentRepository: jest.Mocked<ITournamentRepository>;
    let mockRankingService: jest.Mocked<RankingService>;

    const tournamentId = 'tournament-1';
    const matchId = 'match-1-1';
    const winnerId = 'p1';
    const loserId = 'p2';
    const nextMatchId = 'match-2-1';

    const mockTournament: Tournament = {
        id: tournamentId,
        tenantId: 'tenant-1',
        categories: [{ id: 'cat-1' }]
    } as any;

    let mockBracket: Bracket;
    let mockMatch: BracketMatch;
    let mockNextMatch: BracketMatch;

    beforeEach(() => {
        mockMatch = {
            id: matchId,
            round: 1,
            position: 0,
            player1Id: winnerId,
            player2Id: loserId,
            nextMatchId: nextMatchId
        };

        mockNextMatch = {
            id: nextMatchId,
            round: 2,
            position: 0,
            // player1Id should be filled by winner
        };

        mockBracket = {
            id: 'bracket-1',
            tournamentId,
            categoryId: 'cat-1',
            matches: [mockMatch, mockNextMatch],
            status: 'IN_PROGRESS'
        };

        mockBracketRepository = {
            findByTournamentAndCategory: jest.fn(),
            update: jest.fn(),
        } as any;

        mockTournamentRepository = {
            findById: jest.fn(),
        } as any;

        mockRankingService = {
            processMatchResult: jest.fn(),
        } as any;

        useCase = new RecordTournamentMatchResultUseCase(
            mockBracketRepository,
            mockTournamentRepository,
            mockRankingService
        );
    });

    it('should record match result and advance winner', async () => {
        mockTournamentRepository.findById.mockResolvedValue(mockTournament);
        mockBracketRepository.findByTournamentAndCategory.mockResolvedValue(mockBracket);
        mockBracketRepository.update.mockResolvedValue({ ...mockBracket, status: 'IN_PROGRESS' });

        const input = {
            tournamentId,
            matchId,
            winnerId,
            score: '6-4, 6-4'
        };

        const result = await useCase.execute(input);

        // Verify match update
        const updatedMatch = result.matches.find(m => m.id === matchId);
        expect(updatedMatch?.winnerId).toBe(winnerId);
        expect(updatedMatch?.score).toBe('6-4, 6-4');

        // Verify next match update
        const updatedNextMatch = result.matches.find(m => m.id === nextMatchId);
        expect(updatedNextMatch?.player1Id).toBe(winnerId);

        // Verify calls
        expect(mockRankingService.processMatchResult).toHaveBeenCalledWith({
            winnerId,
            loserId,
            tenantId: 'tenant-1',
            isTournament: true
        });
        expect(mockBracketRepository.update).toHaveBeenCalled();
    });

    it('should throw error if match already has result', async () => {
        const finishedMatch = { ...mockMatch, winnerId: 'p1' };
        const bracketWithFinishedMatch = { ...mockBracket, matches: [finishedMatch] };

        mockTournamentRepository.findById.mockResolvedValue(mockTournament);
        mockBracketRepository.findByTournamentAndCategory.mockResolvedValue(bracketWithFinishedMatch);

        await expect(useCase.execute({ tournamentId, matchId, winnerId, score: '6-0' }))
            .rejects.toThrow('Este match ya tiene un ganador registrado');
    });

    it('should throw error if winner is not one of the players', async () => {
        mockTournamentRepository.findById.mockResolvedValue(mockTournament);
        mockBracketRepository.findByTournamentAndCategory.mockResolvedValue(mockBracket);

        await expect(useCase.execute({ tournamentId, matchId, winnerId: 'other-player', score: '6-0' }))
            .rejects.toThrow('El ganador debe ser uno de los jugadores del match');
    });

    it('should mark bracket as completed if all matches finished', async () => {
        const finalMatch: BracketMatch = {
            id: 'final-match',
            round: 2,
            position: 0,
            player1Id: 'p1',
            player2Id: 'p2'
        };
        const bracket = { ...mockBracket, matches: [finalMatch], status: 'IN_PROGRESS' as const };

        mockTournamentRepository.findById.mockResolvedValue(mockTournament);
        mockBracketRepository.findByTournamentAndCategory.mockResolvedValue(bracket as any);

        // Mock update to return completed bracket
        mockBracketRepository.update.mockImplementation(async (id, update) => {
            if (update.status === 'COMPLETED') {
                return { ...bracket, status: 'COMPLETED' };
            }
            // Simulate memory update for internal check
            const updatedMatches = update.matches || bracket.matches;
            return { ...bracket, matches: updatedMatches } as any;
        });

        await useCase.execute({ tournamentId, matchId: 'final-match', winnerId: 'p1', score: '6-0' });

        expect(mockBracketRepository.update).toHaveBeenCalledWith(expect.any(String), expect.objectContaining({
            status: 'COMPLETED'
        }));
    });
});

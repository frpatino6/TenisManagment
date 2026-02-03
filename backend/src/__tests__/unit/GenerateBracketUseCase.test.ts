import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { GenerateBracketUseCase } from '../../application/use-cases/GenerateBracketUseCase';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { BracketGenerationService } from '../../domain/services/BracketGenerationService';
import { Tournament } from '../../domain/entities/Tournament';
import { Bracket } from '../../domain/entities/Bracket';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';

jest.mock('../../infrastructure/database/models/AuthUserModel', () => ({
    AuthUserModel: {
        find: jest.fn(() => ({
            lean: jest.fn().mockResolvedValue([
                { _id: '507f1f77bcf86cd799439011', name: 'Player 1' },
                { _id: '507f1f77bcf86cd799439012', name: 'Player 2' }
            ])
        }))
    }
}));

describe('GenerateBracketUseCase', () => {
    let useCase: GenerateBracketUseCase;
    let mockTournamentRepository: jest.Mocked<ITournamentRepository>;
    let mockBracketRepository: jest.Mocked<IBracketRepository>;
    let mockBracketGenerationService: jest.Mocked<BracketGenerationService>;

    const tournamentId = 'tournament-1';
    const categoryId = 'category-1';

    const mockTournament: Tournament = {
        id: tournamentId,
        tenantId: 'tenant-1',
        name: 'Torneo Test',
        status: 'DRAFT',
        categories: [
            {
                id: categoryId,
                name: 'Pro',
                participants: ['507f1f77bcf86cd799439011', '507f1f77bcf86cd799439012'],
                prizes: []
            } as any
        ],
        startDate: new Date(),
        endDate: new Date()
    } as Tournament;

    beforeEach(() => {
        mockTournamentRepository = {
            findById: jest.fn(),
            update: jest.fn(),
        } as any;

        mockBracketRepository = {
            findByTournamentAndCategory: jest.fn(),
            create: jest.fn(),
        } as any;

        mockBracketGenerationService = {
            generateSingleEliminationBracket: jest.fn(),
        } as any;

        useCase = new GenerateBracketUseCase(
            mockTournamentRepository,
            mockBracketRepository,
            mockBracketGenerationService
        );
    });

    it('should generate bracket successfully', async () => {
        mockTournamentRepository.findById.mockResolvedValue(mockTournament);
        mockBracketRepository.findByTournamentAndCategory.mockResolvedValue(null);
        mockBracketGenerationService.generateSingleEliminationBracket.mockReturnValue([]);
        mockBracketRepository.create.mockResolvedValue({ id: 'bracket-1' } as Bracket);

        const result = await useCase.execute(tournamentId, categoryId);

        expect(mockTournamentRepository.findById).toHaveBeenCalledWith(tournamentId);
        expect(mockBracketRepository.findByTournamentAndCategory).toHaveBeenCalledWith(tournamentId, categoryId);
        expect(mockBracketGenerationService.generateSingleEliminationBracket).toHaveBeenCalled();
        expect(mockBracketRepository.create).toHaveBeenCalled();
        expect(mockTournamentRepository.update).toHaveBeenCalledWith(tournamentId, { status: 'IN_PROGRESS' });
        expect(result).toHaveProperty('id', 'bracket-1');
    });

    it('should throw error if tournament not found', async () => {
        mockTournamentRepository.findById.mockResolvedValue(null);

        await expect(useCase.execute(tournamentId, categoryId)).rejects.toThrow('Torneo no encontrado');
    });

    it('should throw error if tournament is FINISHED', async () => {
        mockTournamentRepository.findById.mockResolvedValue({ ...mockTournament, status: 'FINISHED' });

        await expect(useCase.execute(tournamentId, categoryId)).rejects.toThrow('No se pueden generar brackets para torneos en estado FINISHED');
    });

    it('should throw error if category not found', async () => {
        mockTournamentRepository.findById.mockResolvedValue(mockTournament);

        await expect(useCase.execute(tournamentId, 'non-existent-cat')).rejects.toThrow('Categoría no encontrada en el torneo');
    });

    it('should throw error if not enough participants', async () => {
        const tournamentWithFewParticipants = {
            ...mockTournament,
            categories: [{ ...mockTournament.categories[0], participants: ['507f1f77bcf86cd799439011'] }]
        };
        mockTournamentRepository.findById.mockResolvedValue(tournamentWithFewParticipants as any);

        await expect(useCase.execute(tournamentId, categoryId)).rejects.toThrow('Se requieren al menos 2 participantes para generar un bracket');
    });

    it('should throw error if bracket already exists', async () => {
        mockTournamentRepository.findById.mockResolvedValue(mockTournament);
        mockBracketRepository.findByTournamentAndCategory.mockResolvedValue({ id: 'existing-b' } as Bracket);

        await expect(useCase.execute(tournamentId, categoryId)).rejects.toThrow('Ya existe un bracket para esta categoría');
    });
});

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { CreateTournamentUseCase } from '../../application/use-cases/CreateTournamentUseCase';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { Tournament } from '../../domain/entities/Tournament';

describe('CreateTournamentUseCase', () => {
    let useCase: CreateTournamentUseCase;
    let mockTournamentRepo: jest.Mocked<ITournamentRepository>;

    const tenantId = 'tenant-1';

    beforeEach(() => {
        mockTournamentRepo = {
            create: jest.fn(),
            findById: jest.fn(),
            findAllByTenant: jest.fn(),
            update: jest.fn(),
            delete: jest.fn(),
            addParticipantToCategory: jest.fn(),
            removeParticipantFromCategory: jest.fn(),
        } as any;

        useCase = new CreateTournamentUseCase(mockTournamentRepo);
    });

    it('should create a tournament with valid data', async () => {
        const startDate = new Date('2026-02-01');
        const endDate = new Date('2026-02-15');

        const input = {
            tenantId,
            name: 'Torneo de Verano',
            description: 'Torneo anual de tenis',
            startDate,
            endDate,
            categories: [
                { name: '3ra Categoría', minElo: 1000, maxElo: 1200 },
                { name: '4ta Categoría', minElo: 800, maxElo: 999 }
            ]
        };

        const expectedTournament: Tournament = {
            id: 't-1',
            tenantId,
            name: input.name,
            description: input.description,
            startDate,
            endDate,
            status: 'DRAFT',
            categories: [
                { id: 'cat-1', name: '3ra Categoría', minElo: 1000, maxElo: 1200, participants: [] },
                { id: 'cat-2', name: '4ta Categoría', minElo: 800, maxElo: 999, participants: [] }
            ]
        };

        mockTournamentRepo.create.mockResolvedValue(expectedTournament);

        const result = await useCase.execute(input);

        expect(mockTournamentRepo.create).toHaveBeenCalledWith(
            expect.objectContaining({
                tenantId,
                name: input.name,
                status: 'DRAFT',
                categories: expect.arrayContaining([
                    expect.objectContaining({ name: '3ra Categoría', participants: [] }),
                    expect.objectContaining({ name: '4ta Categoría', participants: [] })
                ])
            })
        );
        expect(result).toEqual(expectedTournament);
    });

    it('should throw error if startDate is after endDate', async () => {
        const startDate = new Date('2026-02-15');
        const endDate = new Date('2026-02-01');

        const input = {
            tenantId,
            name: 'Torneo Inválido',
            description: 'Fechas incorrectas',
            startDate,
            endDate,
            categories: []
        };

        await expect(useCase.execute(input)).rejects.toThrow('La fecha de inicio debe ser anterior a la fecha de fin');
    });
});

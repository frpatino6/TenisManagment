import { Tournament } from '../../domain/entities/Tournament';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';

export class CreateTournamentUseCase {
    constructor(private tournamentRepository: ITournamentRepository) { }

    async execute(data: {
        tenantId: string;
        name: string;
        description: string;
        startDate: Date;
        endDate: Date;
        categories: Array<{
            name: string;
            gender: 'MALE' | 'FEMALE' | 'MIXED';
            format?: 'SINGLE_ELIMINATION' | 'HYBRID';
            groupStageConfig?: {
                numberOfGroups: number;
                advancePerGroup: number;
                pointsForWin: number;
                pointsForDraw: number;
                pointsForLoss: number;
                seedingMethod: 'RANKING' | 'RANDOM';
            };
            minElo?: number;
            maxElo?: number;
        }>;
    }): Promise<Tournament> {
        // Validaciones básicas
        if (data.startDate >= data.endDate) {
            throw new Error('La fecha de inicio debe ser anterior a la fecha de fin');
        }

        const tournament: Tournament = {
            tenantId: data.tenantId,
            name: data.name,
            description: data.description,
            startDate: data.startDate,
            endDate: data.endDate,
            status: 'DRAFT',
            categories: data.categories.map(cat => ({
                id: '', // Se generará en el repositorio/DB
                name: cat.name,
                gender: cat.gender,
                minElo: cat.minElo,
                maxElo: cat.maxElo,
                participants: [],
                format: cat.format || 'SINGLE_ELIMINATION',
                groupStageConfig: cat.groupStageConfig,
                hasGroupStage: !!cat.groupStageConfig,
                hasBracket: false,
            }))
        };

        return await this.tournamentRepository.create(tournament);
    }
}

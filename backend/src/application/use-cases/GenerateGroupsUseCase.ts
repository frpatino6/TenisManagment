import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { GroupStageGenerationService } from '../../domain/services/GroupStageGenerationService';
import { GroupStage } from '../../domain/entities/GroupStage';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { Types } from 'mongoose';

interface GenerateGroupsInput {
    tournamentId: string;
    categoryId: string;
    config?: {
        numberOfGroups: number;
        playersAdvancingPerGroup: number;
        seedingMethod: 'RANKING' | 'RANDOM';
    };
}

/**
 * Caso de uso para generar grupos balanceados por ranking.
 * 
 * Flujo:
 * 1. Obtiene participantes de la categoría
 * 2. Obtiene ELO de cada participante
 * 3. Aplica snake seeding para balancear grupos
 * 4. Crea GroupStage en estado DRAFT (sin fixtures aún)
 * 5. Organizador puede ajustar grupos antes de confirmar
 */
export class GenerateGroupsUseCase {
    constructor(
        private readonly tournamentRepository: ITournamentRepository,
        private readonly groupStageRepository: GroupStageRepository,
        private readonly rankingRepository: IUserRankingRepository,
        private readonly groupStageService: GroupStageGenerationService
    ) { }

    async execute(input: GenerateGroupsInput): Promise<GroupStage> {
        const { tournamentId, categoryId, config: inputConfig } = input;

        // 1. Obtener torneo y categoría
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        const category = tournament.categories.find((c: any) => c.id === categoryId);
        if (!category) {
            throw new Error('Categoría no encontrada');
        }

        // Usar la configuración enviada o la guardada en la categoría
        const groupStageConfig = inputConfig || category.groupStageConfig;

        if (!groupStageConfig) {
            throw new Error('La categoría no tiene configuración de grupos');
        }

        if (!groupStageConfig.numberOfGroups || groupStageConfig.numberOfGroups <= 0) {
            throw new Error('El número de grupos debe ser mayor a cero');
        }

        // 2. Verificar que no exista ya un GroupStage
        const existing = await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );
        if (existing) {
            throw new Error('Ya existe una fase de grupos para esta categoría');
        }

        // 3. Obtener ELO de todos los participantes
        const participantsWithElo = await this.getParticipantsWithElo(
            category.participants,
            tournament.tenantId
        );

        if (participantsWithElo.length < groupStageConfig.numberOfGroups) {
            throw new Error(`Hay menos participantes (${participantsWithElo.length}) que grupos (${groupStageConfig.numberOfGroups})`);
        }

        // 4. Generar grupos balanceados usando snake seeding
        const groups = this.groupStageService.generateBalancedGroups(
            participantsWithElo,
            groupStageConfig.numberOfGroups
        );

        // 5. Crear GroupStage en estado DRAFT (sin fixtures)
        const groupStage: GroupStage = {
            tournamentId,
            categoryId,
            groups,
            status: 'DRAFT', // Organizador puede ajustar antes de confirmar
        };

        // Actualizar el torneo: persistir config (si se envió) y marcar que ya tiene fase de grupos
        await this.tournamentRepository.update(tournamentId, {
            categories: tournament.categories.map((c: any) => {
                if (c.id === categoryId) {
                    return {
                        ...c,
                        groupStageConfig: inputConfig || c.groupStageConfig,
                        hasGroupStage: true
                    };
                }
                return c;
            })
        });

        return await this.groupStageRepository.create(groupStage);
    }

    private async getParticipantsWithElo(
        participantIds: string[],
        tenantId: string
    ): Promise<Array<{ userId: string; name: string; elo: number }>> {
        const participants = await AuthUserModel.find({
            _id: { $in: participantIds.map(id => new Types.ObjectId(id)) },
        });

        const result = [];

        for (const participant of participants) {
            const ranking = await this.rankingRepository.findByUserAndTenant(
                participant._id.toString(),
                tenantId
            );

            result.push({
                userId: participant._id.toString(),
                name: participant.name || 'Jugador',
                elo: ranking?.eloScore || 1500, // ELO por defecto si no tiene ranking
            });
        }

        return result;
    }
}

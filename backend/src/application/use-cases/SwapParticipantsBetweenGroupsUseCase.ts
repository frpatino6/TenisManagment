import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { GroupStage } from '../../domain/entities/GroupStage';
import { Logger } from '../../infrastructure/services/Logger';

interface SwapParticipantsInput {
    tournamentId: string;
    categoryId: string;
    participant1Id: string;
    group1Id: string;
    participant2Id: string;
    group2Id: string;
}

/**
 * Caso de uso para intercambiar dos participantes entre grupos.
 * 
 * A diferencia de "mover", el intercambio siempre mantiene el balance
 * de los grupos porque se mueven dos jugadores simultáneamente.
 * 
 * Validaciones:
 * - Solo permitido en estado DRAFT
 * - Ambos participantes deben existir en sus respectivos grupos
 * - Los grupos deben ser diferentes
 */
export class SwapParticipantsBetweenGroupsUseCase {
    private readonly logger = new Logger({ service: 'SwapParticipantsBetweenGroupsUseCase' });

    constructor(
        private readonly groupStageRepository: GroupStageRepository
    ) { }

    async execute(input: SwapParticipantsInput): Promise<GroupStage> {
        const { tournamentId, categoryId, participant1Id, group1Id, participant2Id, group2Id } = input;

        this.logger.info('Iniciando intercambio de participantes', {
            tournamentId,
            categoryId,
            participant1Id,
            group1Id,
            participant2Id,
            group2Id
        });

        // 1. Validar que los grupos sean diferentes
        if (group1Id === group2Id) {
            throw new Error('Los participantes deben estar en grupos diferentes');
        }

        // 2. Obtener GroupStage
        const groupStage = await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );

        if (!groupStage) {
            throw new Error('Fase de grupos no encontrada');
        }

        // 3. Validar que esté en estado DRAFT
        if (groupStage.status !== 'DRAFT') {
            throw new Error('Solo se pueden intercambiar jugadores en estado DRAFT');
        }

        // 4. Encontrar grupos
        const group1Index = groupStage.groups.findIndex((g: any) => g.id === group1Id);
        const group2Index = groupStage.groups.findIndex((g: any) => g.id === group2Id);

        if (group1Index === -1 || group2Index === -1) {
            throw new Error('Grupo no encontrado');
        }

        const group1 = groupStage.groups[group1Index];
        const group2 = groupStage.groups[group2Index];

        // 5. Validar que los participantes estén en sus respectivos grupos
        const participant1Index = group1.participants.indexOf(participant1Id);
        const participant2Index = group2.participants.indexOf(participant2Id);

        if (participant1Index === -1) {
            throw new Error('El participante 1 no está en el grupo especificado');
        }

        if (participant2Index === -1) {
            throw new Error('El participante 2 no está en el grupo especificado');
        }

        this.logger.debug('Estado antes del intercambio', {
            group1: { id: group1.id, participants: group1.participants },
            group2: { id: group2.id, participants: group2.participants }
        });

        // 6. Intercambiar participantes en los arrays
        group1.participants[participant1Index] = participant2Id;
        group2.participants[participant2Index] = participant1Id;

        // 7. Intercambiar standings
        const standing1Index = group1.standings.findIndex((s: any) => s.playerId === participant1Id);
        const standing2Index = group2.standings.findIndex((s: any) => s.playerId === participant2Id);

        if (standing1Index !== -1 && standing2Index !== -1) {
            const standing1 = group1.standings[standing1Index];
            const standing2 = group2.standings[standing2Index];

            // Intercambiar los standings entre grupos
            group1.standings[standing1Index] = standing2;
            group2.standings[standing2Index] = standing1;
        }

        this.logger.debug('Estado después del intercambio', {
            group1: { id: group1.id, participants: group1.participants },
            group2: { id: group2.id, participants: group2.participants }
        });

        // 8. Guardar cambios
        this.logger.info('Guardando intercambio en base de datos');
        const result = await this.groupStageRepository.update(groupStage);

        this.logger.info('Intercambio completado exitosamente');

        return result;
    }
}

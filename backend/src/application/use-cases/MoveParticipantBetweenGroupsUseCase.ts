import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { GroupStage } from '../../domain/entities/GroupStage';

interface MoveParticipantInput {
    tournamentId: string;
    categoryId: string;
    participantId: string;
    fromGroupId: string;
    toGroupId: string;
}

/**
 * Caso de uso para mover un participante entre grupos (drag & drop).
 * 
 * Validaciones:
 * - Solo permitido en estado DRAFT
 * - Los grupos deben mantener tamaños similares (±1 jugador)
 */
export class MoveParticipantBetweenGroupsUseCase {
    constructor(
        private readonly groupStageRepository: GroupStageRepository
    ) { }

    async execute(input: MoveParticipantInput): Promise<GroupStage> {
        const { tournamentId, categoryId, participantId, fromGroupId, toGroupId } = input;

        // 1. Obtener GroupStage
        const groupStage = await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );

        if (!groupStage) {
            throw new Error('Fase de grupos no encontrada');
        }

        // 2. Validar que esté en estado DRAFT
        if (groupStage.status !== 'DRAFT') {
            throw new Error('Solo se pueden mover jugadores en estado DRAFT');
        }

        // 3. Encontrar grupos
        const fromGroup = groupStage.groups.find((g: any) => g.id === fromGroupId);
        const toGroup = groupStage.groups.find((g: any) => g.id === toGroupId);

        if (!fromGroup || !toGroup) {
            throw new Error('Grupo no encontrado');
        }

        // 4. Validar que el participante esté en el grupo origen
        if (!fromGroup.participants.includes(participantId)) {
            throw new Error('El participante no está en el grupo origen');
        }

        // 5. Validar diferencia de tamaño (máximo ±1)
        const newFromSize = fromGroup.participants.length - 1;
        const newToSize = toGroup.participants.length + 1;

        if (Math.abs(newToSize - newFromSize) > 1) {
            throw new Error('Los grupos deben mantener tamaños similares (diferencia máxima: 1 jugador)');
        }

        // 6. Mover participante
        fromGroup.participants = fromGroup.participants.filter(p => p !== participantId);
        toGroup.participants.push(participantId);

        // 7. Actualizar standings (recalcular posiciones)
        const participantInFromStanding = fromGroup.standings.find((s: any) => s.playerId === participantId);
        const participantInToStanding = toGroup.standings.find((s: any) => s.playerId === participantId);

        if (participantInFromStanding) {
            fromGroup.standings = fromGroup.standings.filter((s: any) => s.playerId !== participantId);
            toGroup.standings.push(participantInFromStanding);
        }

        // 8. Guardar cambios
        return await this.groupStageRepository.update(groupStage);
    }
}

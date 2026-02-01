import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { GroupStage } from '../../domain/entities/GroupStage';
import { Logger } from '../../infrastructure/services/Logger';

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
    private readonly logger = new Logger({ service: 'MoveParticipantBetweenGroupsUseCase' });

    constructor(
        private readonly groupStageRepository: GroupStageRepository
    ) { }

    async execute(input: MoveParticipantInput): Promise<GroupStage> {
        const { tournamentId, categoryId, participantId, fromGroupId, toGroupId } = input;

        this.logger.info('Iniciando movimiento de participante', {
            tournamentId,
            categoryId,
            participantId,
            fromGroupId,
            toGroupId
        });

        // 1. Obtener GroupStage
        const groupStage = await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );

        if (!groupStage) {
            throw new Error('Fase de grupos no encontrada');
        }

        this.logger.debug('GroupStage encontrado', {
            status: groupStage.status,
            groupsCount: groupStage.groups.length,
            groupIds: groupStage.groups.map(g => g.id)
        });

        // 2. Validar que esté en estado DRAFT
        if (groupStage.status !== 'DRAFT') {
            throw new Error('Solo se pueden mover jugadores en estado DRAFT');
        }

        // 3. Encontrar grupos
        const fromGroupIndex = groupStage.groups.findIndex((g: any) => g.id === fromGroupId);
        const toGroupIndex = groupStage.groups.findIndex((g: any) => g.id === toGroupId);

        this.logger.debug('Índices de grupos', { fromGroupIndex, toGroupIndex });

        if (fromGroupIndex === -1 || toGroupIndex === -1) {
            throw new Error('Grupo no encontrado');
        }

        const fromGroup = groupStage.groups[fromGroupIndex];
        const toGroup = groupStage.groups[toGroupIndex];

        this.logger.debug('Grupo origen antes de mover', {
            groupId: fromGroup.id,
            participants: fromGroup.participants,
            standingsCount: fromGroup.standings.length
        });

        this.logger.debug('Grupo destino antes de mover', {
            groupId: toGroup.id,
            participants: toGroup.participants,
            standingsCount: toGroup.standings.length
        });

        // 4. Validar que el participante esté en el grupo origen
        const participantIndex = fromGroup.participants.indexOf(participantId);
        this.logger.debug('Buscando participante en grupo origen', {
            participantId,
            participantIndex,
            participantsInGroup: fromGroup.participants
        });

        if (participantIndex === -1) {
            throw new Error('El participante no está en el grupo origen');
        }

        // 5. Validar diferencia de tamaño (máximo ±1)
        const newFromSize = fromGroup.participants.length - 1;
        const newToSize = toGroup.participants.length + 1;

        if (Math.abs(newToSize - newFromSize) > 1) {
            throw new Error('Los grupos deben mantener tamaños similares (diferencia máxima: 1 jugador)');
        }

        // 6. Mover participante usando splice para modificar el array original
        fromGroup.participants.splice(participantIndex, 1);
        toGroup.participants.push(participantId);

        // 7. Actualizar standings
        const standingIndex = fromGroup.standings.findIndex((s: any) => s.playerId === participantId);
        if (standingIndex !== -1) {
            const [movedStanding] = fromGroup.standings.splice(standingIndex, 1);
            toGroup.standings.push(movedStanding);
        }

        this.logger.debug('Grupo origen después de mover', {
            groupId: fromGroup.id,
            participants: fromGroup.participants,
            standingsCount: fromGroup.standings.length
        });

        this.logger.debug('Grupo destino después de mover', {
            groupId: toGroup.id,
            participants: toGroup.participants,
            standingsCount: toGroup.standings.length
        });

        // 8. Guardar cambios
        this.logger.info('Guardando cambios en base de datos');
        const result = await this.groupStageRepository.update(groupStage);

        this.logger.info('Movimiento completado exitosamente', {
            resultGroupsCount: result.groups.length
        });

        return result;
    }
}

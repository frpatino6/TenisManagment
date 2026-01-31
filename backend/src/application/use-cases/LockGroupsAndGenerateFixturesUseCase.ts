import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { GroupStageGenerationService } from '../../domain/services/GroupStageGenerationService';
import { GroupStage } from '../../domain/entities/GroupStage';

interface LockGroupsInput {
    tournamentId: string;
    categoryId: string;
}

/**
 * Caso de uso para bloquear grupos y generar fixtures.
 * 
 * Flujo:
 * 1. Valida que esté en estado DRAFT
 * 2. Genera todos los fixtures round robin para cada grupo
 * 3. Cambia estado a LOCKED (ya no se pueden modificar grupos)
 * 4. Los partidos están listos para ser jugados
 */
export class LockGroupsAndGenerateFixturesUseCase {
    constructor(
        private readonly groupStageRepository: GroupStageRepository,
        private readonly groupStageService: GroupStageGenerationService
    ) { }

    async execute(input: LockGroupsInput): Promise<GroupStage> {
        const { tournamentId, categoryId } = input;

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
            throw new Error('Los grupos ya están bloqueados');
        }

        // 3. Generar fixtures round robin para cada grupo
        groupStage.groups.forEach(group => {
            group.matches = this.groupStageService.generateRoundRobinFixtures(
                group.participants,
                group.id
            );
        });

        // 4. Cambiar estado a LOCKED
        groupStage.status = 'LOCKED';

        // 5. Guardar cambios
        return await this.groupStageRepository.update(groupStage);
    }
}

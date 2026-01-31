import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';

export class DeleteGroupStageUseCase {
    constructor(
        private tournamentRepository: ITournamentRepository,
        private groupStageRepository: GroupStageRepository
    ) { }

    async execute(tournamentId: string, categoryId: string): Promise<void> {
        // 1. Validar que el torneo exista
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        // 2. Buscar la fase de grupos
        const groupStage = await this.groupStageRepository.findByTournamentAndCategory(tournamentId, categoryId);
        if (!groupStage) {
            throw new Error('No existe una fase de grupos para esta categoría');
        }

        // 3. Validar que no tenga resultados grabados en ningún grupo
        const hasResults = groupStage.groups.some(group =>
            group.matches.some(m => m.winnerId || m.score)
        );

        if (hasResults) {
            throw new Error('No se puede eliminar una fase de grupos que ya tiene resultados registrados');
        }

        // 4. Eliminar la fase de grupos
        await this.groupStageRepository.delete(tournamentId, categoryId);

        // 5. Actualizar la categoría del torneo
        const updatedCategories = tournament.categories.map(c => {
            if (c.id === categoryId) {
                return { ...c, hasGroupStage: false };
            }
            return c;
        });

        await this.tournamentRepository.update(tournamentId, {
            categories: updatedCategories
        });
    }
}

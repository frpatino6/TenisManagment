import { GroupStage } from '../../domain/entities/GroupStage';

/**
 * Repositorio para gestionar la persistencia de GroupStages.
 */
export interface GroupStageRepository {
    /**
     * Crea una nueva fase de grupos.
     */
    create(groupStage: GroupStage): Promise<GroupStage>;

    /**
     * Encuentra una fase de grupos por torneo y categoría.
     */
    findByTournamentAndCategory(tournamentId: string, categoryId: string): Promise<GroupStage | null>;

    /**
     * Actualiza una fase de grupos existente.
     */
    update(groupStage: GroupStage): Promise<GroupStage>;

    /**
     * Elimina una fase de grupos.
     */
    delete(tournamentId: string, categoryId: string): Promise<void>;
}

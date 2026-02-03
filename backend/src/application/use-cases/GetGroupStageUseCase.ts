import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { GroupStage } from '../../domain/entities/GroupStage';

interface GetGroupStageInput {
    tournamentId: string;
    categoryId: string;
}

/**
 * Caso de uso para obtener el GroupStage de una categoría.
 */
export class GetGroupStageUseCase {
    constructor(
        private readonly groupStageRepository: GroupStageRepository
    ) { }

    async execute(input: GetGroupStageInput): Promise<GroupStage | null> {
        const { tournamentId, categoryId } = input;

        return await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );
    }
}

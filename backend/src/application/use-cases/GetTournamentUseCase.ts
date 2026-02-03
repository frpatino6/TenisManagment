import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { Tournament } from '../../domain/entities/Tournament';

export class GetTournamentUseCase {
    constructor(private readonly tournamentRepository: ITournamentRepository) { }

    async execute(id: string): Promise<Tournament | null> {
        if (!id) {
            throw new Error('Tournament ID is required');
        }
        return this.tournamentRepository.findById(id);
    }
}

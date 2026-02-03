import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';

export class DeleteBracketUseCase {
    constructor(
        private tournamentRepository: ITournamentRepository,
        private bracketRepository: IBracketRepository
    ) { }

    async execute(tournamentId: string, categoryId: string): Promise<void> {
        // 1. Validar que el torneo exista
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        // 2. Buscar el bracket
        const bracket = await this.bracketRepository.findByTournamentAndCategory(tournamentId, categoryId);
        if (!bracket) {
            throw new Error('No existe un cuadro para esta categoría');
        }

        // 3. Validar que no tenga resultados grabados
        const hasResults = bracket.matches.some(m => m.winnerId || m.score);
        if (hasResults) {
            throw new Error('No se puede eliminar un cuadro que ya tiene resultados registrados');
        }

        // 4. Eliminar el bracket
        await this.bracketRepository.delete(tournamentId, categoryId);

        // 5. Actualizar la categoría del torneo
        const updatedCategories = tournament.categories.map(c => {
            if (c.id === categoryId) {
                return { ...c, hasBracket: false };
            }
            return c;
        });

        await this.tournamentRepository.update(tournamentId, {
            categories: updatedCategories
        });
    }
}

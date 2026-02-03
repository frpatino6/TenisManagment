import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';

export class EnrollPlayerUseCase {
    constructor(
        private readonly tournamentRepository: ITournamentRepository,
        private readonly bracketRepository: IBracketRepository
    ) { }

    async execute(tournamentId: string, categoryId: string, userId: string): Promise<void> {
        // 1. Verificar que el torneo exista
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        // 2. Verificar estado del torneo (Solo DRAFT)
        if (tournament.status !== 'DRAFT') {
            throw new Error('Solo se pueden inscribir jugadores en torneos en estado DRAFT');
        }

        // 3. Verificar que la categoría exista
        const category = tournament.categories.find(c => c.id === categoryId);
        if (!category) {
            throw new Error('Categoría no encontrada');
        }

        // 4. Verificar si ya existe un bracket (no debería si es DRAFT, pero por seguridad)
        const existingBracket = await this.bracketRepository.findByTournamentAndCategory(tournamentId, categoryId);
        if (existingBracket) {
            throw new Error('No se pueden inscribir jugadores si ya existe un bracket');
        }

        // 5. Verificar si el usuario ya está inscrito en esta categoría
        if (category.participants.includes(userId)) {
            throw new Error('El jugador ya está inscrito en esta categoría');
        }

        // 6. Inscribir al jugador
        await this.tournamentRepository.addParticipantToCategory(tournamentId, categoryId, userId);
    }
}

import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { BracketGenerationService } from '../../domain/services/BracketGenerationService';
import { Bracket } from '../../domain/entities/Bracket';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { Types } from 'mongoose';

export class GenerateBracketUseCase {
    constructor(
        private tournamentRepository: ITournamentRepository,
        private bracketRepository: IBracketRepository,
        private bracketGenerationService: BracketGenerationService
    ) { }

    /**
     * Genera un bracket para una categoría específica de un torneo.
     * 
     * @param tournamentId - ID del torneo
     * @param categoryId - ID de la categoría
     * @returns El bracket generado
     * @throws Error si el torneo no existe, no está en DRAFT, o la categoría no existe
     */
    async execute(tournamentId: string, categoryId: string): Promise<Bracket> {
        // 1. Validar que el torneo exista
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        // 2. Validar que el torneo esté en estado DRAFT o IN_PROGRESS
        const allowedStatuses = ['DRAFT', 'IN_PROGRESS'];
        if (!allowedStatuses.includes(tournament.status)) {
            throw new Error(`No se pueden generar brackets para torneos en estado ${tournament.status}`);
        }

        // 3. Buscar la categoría
        const category = tournament.categories.find(c => c.id === categoryId);
        if (!category) {
            throw new Error('Categoría no encontrada en el torneo');
        }

        // 4. Validar que haya suficientes participantes
        if (category.participants.length < 2) {
            throw new Error('Se requieren al menos 2 participantes para generar un bracket');
        }

        // 5. Verificar que no exista ya un bracket para esta categoría
        const existingBracket = await this.bracketRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );

        if (existingBracket) {
            throw new Error('Ya existe un bracket para esta categoría');
        }

        // 6. Obtener nombres de todos los participantes
        const participantsData = await AuthUserModel.find({
            _id: { $in: category.participants.map(p => new Types.ObjectId(p)) }
        }).lean();

        const nameMap: Record<string, string> = {};
        participantsData.forEach(p => {
            nameMap[p._id.toString()] = p.name || 'Sin Nombre';
        });

        // 7. Generar el bracket usando el servicio de dominio
        // TODO: Ordenar participantes por ELO antes de generar
        const matches = this.bracketGenerationService.generateSingleEliminationBracket(
            category.participants
        );

        // 8. Enriquecer matches con nombres
        matches.forEach(match => {
            if (match.player1Id) match.player1Name = nameMap[match.player1Id];
            if (match.player2Id) match.player2Name = nameMap[match.player2Id];
            if (match.winnerId) match.winnerName = nameMap[match.winnerId];
        });

        // 9. Crear y persistir el bracket
        const bracket: Bracket = {
            tournamentId,
            categoryId,
            matches,
            status: 'PENDING'
        };

        const createdBracket = await this.bracketRepository.create(bracket);

        // 8. Actualizar estado del torneo a IN_PROGRESS
        await this.tournamentRepository.update(tournamentId, {
            status: 'IN_PROGRESS'
        });

        return createdBracket;
    }
}

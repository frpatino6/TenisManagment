import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { RankingService } from '../services/RankingService';
import { Bracket, BracketMatch } from '../../domain/entities/Bracket';

interface RecordMatchResultInput {
    tournamentId: string;
    matchId: string;
    winnerId: string;
    score: string;
}

export class RecordTournamentMatchResultUseCase {
    constructor(
        private bracketRepository: IBracketRepository,
        private tournamentRepository: ITournamentRepository,
        private rankingService: RankingService
    ) { }

    /**
     * Registra el resultado de un partido de torneo.
     * 
     * @param input - Datos del resultado
     * @returns El bracket actualizado
     * @throws Error si las validaciones fallan
     */
    async execute(input: RecordMatchResultInput): Promise<Bracket> {
        const { tournamentId, matchId, winnerId, score } = input;

        // 1. Buscar el bracket del torneo
        const tournament = await this.tournamentRepository.findById(tournamentId);
        if (!tournament) {
            throw new Error('Torneo no encontrado');
        }

        // Buscar el bracket en todas las categorías
        let bracket: Bracket | null = null;
        let currentMatch: BracketMatch | undefined;

        for (const category of tournament.categories) {
            const categoryBracket = await this.bracketRepository.findByTournamentAndCategory(
                tournamentId,
                category.id!
            );

            if (categoryBracket) {
                const match = categoryBracket.matches.find(m => m.id === matchId);
                if (match) {
                    bracket = categoryBracket;
                    currentMatch = match;
                    break;
                }
            }
        }

        if (!bracket || !currentMatch) {
            throw new Error('Match no encontrado en ningún bracket del torneo');
        }

        // 2. Validaciones
        if (currentMatch.winnerId) {
            // Si es un BYE, permitir "re-registrar" para evitar errores si el admin hace clic por error
            const isBye = !currentMatch.player1Id || !currentMatch.player2Id;
            if (!isBye) {
                throw new Error('Este match ya tiene un ganador registrado');
            }
        }

        // Permitir BYEs (solo un jugador asignado)
        if (!currentMatch.player1Id && !currentMatch.player2Id) {
            throw new Error('El match debe tener al menos un jugador asignado');
        }

        if (winnerId !== currentMatch.player1Id && winnerId !== currentMatch.player2Id) {
            throw new Error('El ganador debe ser uno de los jugadores del match');
        }

        // 3. Determinar el perdedor (puede ser null en caso de BYE)
        let loserId: string | undefined;
        if (currentMatch.player1Id && currentMatch.player2Id) {
            loserId = winnerId === currentMatch.player1Id
                ? currentMatch.player2Id
                : currentMatch.player1Id;
        }

        // 4. Actualizar el match con el resultado
        currentMatch.winnerId = winnerId;
        currentMatch.score = score;
        currentMatch.matchDate = new Date();

        // 5. Avanzar al ganador al siguiente match (si existe)
        if (currentMatch.nextMatchId) {
            const nextMatch = bracket.matches.find(m => m.id === currentMatch.nextMatchId);

            if (nextMatch) {
                const winnerName = winnerId === currentMatch.player1Id
                    ? currentMatch.player1Name
                    : currentMatch.player2Name;

                // Determinar si va a player1 o player2 según la posición
                if (currentMatch.position % 2 === 0) {
                    nextMatch.player1Id = winnerId;
                    nextMatch.player1Name = winnerName;
                } else {
                    nextMatch.player2Id = winnerId;
                    nextMatch.player2Name = winnerName;
                }
            }
        }

        // 6. Actualizar el bracket en la base de datos
        const updatedBracket = await this.bracketRepository.update(bracket.id!, {
            matches: bracket.matches
        });

        if (!updatedBracket) {
            throw new Error('Error al actualizar el bracket');
        }

        // 7. Actualizar el ranking global (solo si hay un perdedor real, no BYE)
        if (loserId) {
            await this.rankingService.processMatchResult({
                winnerId,
                loserId,
                tenantId: tournament.tenantId,
                isTournament: true // Aplica multiplicador x2.5
            });
        }

        // 8. Verificar si el bracket está completo
        const allMatchesCompleted = updatedBracket.matches.every(m =>
            m.winnerId !== undefined || (!m.player1Id || !m.player2Id)
        );

        if (allMatchesCompleted && updatedBracket.status !== 'COMPLETED') {
            await this.bracketRepository.update(updatedBracket.id!, {
                status: 'COMPLETED'
            });
            updatedBracket.status = 'COMPLETED';

            // 9. Identificar campeón y subcampeón
            // El último match es el que no tiene nextMatchId
            const finalMatch = bracket.matches.find(m => !m.nextMatchId);
            if (finalMatch && finalMatch.winnerId) {
                const championId = finalMatch.winnerId;
                const runnerUpId = championId === finalMatch.player1Id
                    ? finalMatch.player2Id
                    : finalMatch.player1Id;

                // Actualizar la categoría en el torneo
                const categoryIndex = tournament.categories.findIndex(c => c.id === bracket!.categoryId);
                if (categoryIndex !== -1) {
                    tournament.categories[categoryIndex].championId = championId;
                    tournament.categories[categoryIndex].runnerUpId = runnerUpId;

                    // Verificar si todas las categorías del torneo han terminado
                    // Un torneo termina si todas sus categorías tienen un campeón
                    const allCategoriesFinished = tournament.categories.every(c => c.championId);
                    if (allCategoriesFinished) {
                        tournament.status = 'FINISHED';
                    }

                    await this.tournamentRepository.update(tournament.id!, {
                        categories: tournament.categories,
                        status: tournament.status
                    });
                }
            }

        } else if (updatedBracket.status === 'PENDING') {
            // Cambiar a IN_PROGRESS al registrar el primer resultado
            await this.bracketRepository.update(updatedBracket.id!, {
                status: 'IN_PROGRESS'
            });
            updatedBracket.status = 'IN_PROGRESS';

            // También actualizar el torneo a IN_PROGRESS si estaba en DRAFT/CREATED
            if (tournament.status !== 'IN_PROGRESS' && tournament.status !== 'FINISHED') {
                await this.tournamentRepository.update(tournament.id!, {
                    status: 'IN_PROGRESS'
                });
            }
        }

        return updatedBracket;
    }
}

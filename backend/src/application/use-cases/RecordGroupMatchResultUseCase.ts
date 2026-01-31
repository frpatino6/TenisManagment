import { GroupStageRepository } from '../../domain/repositories/GroupStageRepository';
import { GroupStageGenerationService } from '../../domain/services/GroupStageGenerationService';
import { GroupStage } from '../../domain/entities/GroupStage';

interface RecordGroupMatchResultInput {
    tournamentId: string;
    categoryId: string;
    matchId: string;
    winnerId: string;
    score: string; // Formato: "6-4, 6-3"
}

/**
 * Caso de uso para registrar el resultado de un partido de grupo.
 * 
 * Flujo:
 * 1. Encuentra el partido en el grupo correspondiente
 * 2. Actualiza el resultado y ganador
 * 3. Recalcula los standings del grupo
 * 4. Actualiza posiciones y marca clasificados si todos los partidos están completos
 */
export class RecordGroupMatchResultUseCase {
    constructor(
        private readonly groupStageRepository: GroupStageRepository,
        private readonly groupStageService: GroupStageGenerationService
    ) { }

    async execute(input: RecordGroupMatchResultInput): Promise<GroupStage> {
        const { tournamentId, categoryId, matchId, winnerId, score } = input;

        // 1. Obtener GroupStage
        const groupStage = await this.groupStageRepository.findByTournamentAndCategory(
            tournamentId,
            categoryId
        );

        if (!groupStage) {
            throw new Error('Fase de grupos no encontrada');
        }

        // 2. Encontrar el partido
        let targetGroup = null;
        let targetMatch = null;

        for (const group of groupStage.groups) {
            const match = group.matches.find((m: any) => m.id === matchId);
            if (match) {
                targetGroup = group;
                targetMatch = match;
                break;
            }
        }

        if (!targetGroup || !targetMatch) {
            throw new Error('Partido no encontrado');
        }

        // 3. Validar que el ganador sea uno de los jugadores
        if (targetMatch.player1Id !== winnerId && targetMatch.player2Id !== winnerId) {
            throw new Error('El ganador debe ser uno de los jugadores del partido');
        }

        // 4. Actualizar resultado del partido
        targetMatch.winnerId = winnerId;
        targetMatch.score = score;
        targetMatch.matchDate = new Date();

        // 5. Parsear score para actualizar estadísticas
        const { setsWon, setsLost, gamesWon, gamesLost } = this.parseScore(score);
        const loserId = targetMatch.player1Id === winnerId
            ? targetMatch.player2Id
            : targetMatch.player1Id;

        // 6. Actualizar standings
        const winnerStanding = targetGroup.standings.find((s: any) => s.playerId === winnerId);
        const loserStanding = targetGroup.standings.find((s: any) => s.playerId === loserId);

        if (winnerStanding && loserStanding) {
            // Actualizar ganador
            winnerStanding.matchesPlayed += 1;
            winnerStanding.wins += 1;
            winnerStanding.points += 3; // 3 puntos por victoria
            winnerStanding.setsWon += setsWon;
            winnerStanding.setsLost += setsLost;
            winnerStanding.gamesWon += gamesWon;
            winnerStanding.gamesLost += gamesLost;
            winnerStanding.setDifference = winnerStanding.setsWon - winnerStanding.setsLost;
            winnerStanding.gameDifference = winnerStanding.gamesWon - winnerStanding.gamesLost;

            // Actualizar perdedor
            loserStanding.matchesPlayed += 1;
            loserStanding.losses += 1;
            loserStanding.points += 0; // 0 puntos por derrota
            loserStanding.setsWon += setsLost; // Los sets perdidos del ganador son ganados del perdedor
            loserStanding.setsLost += setsWon;
            loserStanding.gamesWon += gamesLost;
            loserStanding.gamesLost += gamesWon;
            loserStanding.setDifference = loserStanding.setsWon - loserStanding.setsLost;
            loserStanding.gameDifference = loserStanding.gamesWon - loserStanding.gamesLost;
        }

        // 7. Recalcular posiciones del grupo
        targetGroup.standings = this.groupStageService.recalculateStandings(targetGroup.standings);

        // 8. Verificar si todos los partidos del grupo están completos
        const allMatchesPlayed = targetGroup.matches.every((m: any) => m.winnerId);

        if (allMatchesPlayed && groupStage.status === 'LOCKED') {
            groupStage.status = 'IN_PROGRESS';
        }

        // 9. Verificar si todos los grupos están completos
        const allGroupsComplete = groupStage.groups.every((g: any) =>
            g.matches.every((m: any) => m.winnerId)
        );

        if (allGroupsComplete) {
            groupStage.status = 'COMPLETED';
        }

        // 10. Guardar cambios
        return await this.groupStageRepository.update(groupStage);
    }

    /**
     * Parsea el score para extraer estadísticas.
     * Formato esperado: "6-4, 6-3" o "6-4, 3-6, 7-5"
     */
    private parseScore(score: string): {
        setsWon: number;
        setsLost: number;
        gamesWon: number;
        gamesLost: number;
    } {
        const sets = score.split(',').map(s => s.trim());
        let setsWon = 0;
        let setsLost = 0;
        let gamesWon = 0;
        let gamesLost = 0;

        for (const set of sets) {
            const [g1, g2] = set.split('-').map(g => parseInt(g.trim()));

            if (g1 > g2) {
                setsWon++;
            } else {
                setsLost++;
            }

            gamesWon += g1;
            gamesLost += g2;
        }

        return { setsWon, setsLost, gamesWon, gamesLost };
    }
}

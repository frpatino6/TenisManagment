import { Group, GroupStanding, GroupStageMatch } from '../entities/GroupStage';
import { v4 as uuidv4 } from 'uuid';

interface ParticipantWithElo {
    userId: string;
    name: string;
    elo: number;
}

/**
 * Servicio de dominio para generar y gestionar fases de grupos (Round Robin).
 */
export class GroupStageGenerationService {
    /**
     * Genera grupos balanceados usando el algoritmo "Snake Seeding".
     * Este es el mismo algoritmo usado en torneos profesionales ATP/WTA.
     * 
     * Ejemplo con 16 jugadores en 4 grupos:
     * Ranking:  1  2  3  4  5  6  7  8  9 10 11 12 13 14 15 16
     * 
     * Grupo A:  1        8  9       16
     * Grupo B:     2  7       10 15
     * Grupo C:        3  6    11 14
     * Grupo D:           4  5    12 13
     * 
     * @param participants - Participantes con su ELO
     * @param numberOfGroups - Número de grupos a crear
     * @returns Grupos balanceados
     */
    generateBalancedGroups(
        participants: ParticipantWithElo[],
        numberOfGroups: number
    ): Group[] {
        // 1. Ordenar participantes por ELO descendente (mejor primero)
        const sorted = [...participants].sort((a, b) => b.elo - a.elo);

        // 2. Crear estructura de grupos vacíos
        const groups: Group[] = Array(numberOfGroups)
            .fill(null)
            .map((_, i) => ({
                id: `group-${String.fromCharCode(65 + i)}`, // A, B, C, D...
                name: `Grupo ${String.fromCharCode(65 + i)}`,
                seed: i + 1,
                participants: [],
                matches: [],
                standings: [],
            }));

        // 3. Aplicar snake seeding
        let groupIndex = 0;
        let direction = 1; // 1 = forward, -1 = backward

        for (const participant of sorted) {
            groups[groupIndex].participants.push(participant.userId);

            groupIndex += direction;

            // Cambiar dirección al llegar a los extremos (efecto "serpiente")
            if (groupIndex >= numberOfGroups) {
                groupIndex = numberOfGroups - 1;
                direction = -1;
            } else if (groupIndex < 0) {
                groupIndex = 0;
                direction = 1;
            }
        }

        // 4. Inicializar standings para cada grupo
        groups.forEach(group => {
            group.standings = this.initializeStandings(
                group.participants,
                participants
            );
        });

        return groups;
    }

    /**
     * Genera fixtures de Round Robin para un grupo.
     * Cada jugador juega contra todos los demás una vez.
     * 
     * @param participants - IDs de participantes del grupo
     * @param groupId - ID del grupo
     * @returns Partidos generados
     */
    generateRoundRobinFixtures(
        participants: string[],
        groupId: string
    ): GroupStageMatch[] {
        const matches: GroupStageMatch[] = [];
        let round = 1;

        // Generar todos los enfrentamientos posibles
        for (let i = 0; i < participants.length; i++) {
            for (let j = i + 1; j < participants.length; j++) {
                matches.push({
                    id: uuidv4(),
                    groupId,
                    player1Id: participants[i],
                    player2Id: participants[j],
                    round,
                });
            }
        }

        return matches;
    }

    /**
     * Inicializa la tabla de posiciones para un grupo.
     * 
     * @param participantIds - IDs de participantes
     * @param participantsData - Datos completos de participantes (con ELO)
     * @returns Standings inicializados
     */
    private initializeStandings(
        participantIds: string[],
        participantsData: ParticipantWithElo[]
    ): GroupStanding[] {
        return participantIds.map((playerId, index) => {
            const participant = participantsData.find(p => p.userId === playerId);

            return {
                playerId,
                playerName: participant?.name,
                playerElo: participant?.elo,
                position: index + 1, // Se actualizará después de jugar partidos
                matchesPlayed: 0,
                wins: 0,
                draws: 0,
                losses: 0,
                points: 0,
                setsWon: 0,
                setsLost: 0,
                gamesWon: 0,
                gamesLost: 0,
                setDifference: 0,
                gameDifference: 0,
                qualifiedForKnockout: false,
            };
        });
    }

    /**
     * Recalcula la tabla de posiciones de un grupo después de actualizar un resultado.
     * 
     * Criterios de desempate (en orden):
     * 1. Puntos
     * 2. Diferencia de sets
     * 3. Diferencia de games
     * 4. Sets ganados
     * 5. Games ganados
     * 
     * @param standings - Standings actuales
     * @returns Standings ordenados y con posiciones actualizadas
     */
    recalculateStandings(standings: GroupStanding[]): GroupStanding[] {
        // Ordenar por criterios de desempate
        const sorted = [...standings].sort((a, b) => {
            // 1. Puntos
            if (b.points !== a.points) return b.points - a.points;

            // 2. Diferencia de sets
            if (b.setDifference !== a.setDifference) {
                return b.setDifference - a.setDifference;
            }

            // 3. Diferencia de games
            if (b.gameDifference !== a.gameDifference) {
                return b.gameDifference - a.gameDifference;
            }

            // 4. Sets ganados
            if (b.setsWon !== a.setsWon) return b.setsWon - a.setsWon;

            // 5. Games ganados
            return b.gamesWon - a.gamesWon;
        });

        // Actualizar posiciones
        sorted.forEach((standing, index) => {
            standing.position = index + 1;
        });

        return sorted;
    }
}

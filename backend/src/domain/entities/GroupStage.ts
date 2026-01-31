export type GroupStageStatus = 'DRAFT' | 'LOCKED' | 'IN_PROGRESS' | 'COMPLETED';

export interface GroupStageMatch {
    id: string;
    groupId: string;
    player1Id: string;
    player1Name?: string;
    player1Elo?: number;       // Para mostrar en UI
    player2Id: string;
    player2Name?: string;
    player2Elo?: number;
    winnerId?: string;
    score?: string;
    matchDate?: Date;
    round?: number; // Jornada dentro del grupo
}

export interface GroupStanding {
    playerId: string;
    playerName?: string;
    playerElo?: number;        // Ranking al momento de la generación
    position: number;          // 1°, 2°, 3°, 4° en el grupo
    matchesPlayed: number;
    wins: number;
    draws: number;
    losses: number;
    points: number;
    setsWon: number;
    setsLost: number;
    gamesWon: number;
    gamesLost: number;
    setDifference: number;     // Para desempates
    gameDifference: number;    // Para desempates
    qualifiedForKnockout: boolean; // true si clasifica a fase final
}

export interface Group {
    id: string;
    name: string;              // "Grupo A", "Grupo B", etc.
    seed: number;              // 1 = Grupo más fuerte (por suma de ELOs)
    participants: string[];    // IDs de jugadores en este grupo
    matches: GroupStageMatch[];
    standings: GroupStanding[];
}

/**
 * Entidad de dominio que representa la Fase de Grupos de un Torneo.
 */
export interface GroupStage {
    id?: string;
    tournamentId: string;
    categoryId: string;
    groups: Group[];
    status: GroupStageStatus;
    // DRAFT: Grupos generados, organizador puede ajustar
    // LOCKED: Organizador confirmó, no se puede modificar
    // IN_PROGRESS: Partidos en curso
    // COMPLETED: Todos los partidos jugados
    createdAt?: Date;
    updatedAt?: Date;
}

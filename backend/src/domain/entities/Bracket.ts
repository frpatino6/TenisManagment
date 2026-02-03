export type BracketStatus = 'PENDING' | 'IN_PROGRESS' | 'COMPLETED';

/**
 * Representa un partido individual dentro del bracket.
 */
export interface BracketMatch {
    id: string;
    round: number; // 1=Final, 2=Semifinal, 3=Cuartos, etc.
    position: number; // Posición dentro de la ronda
    player1Id?: string; // undefined = BYE
    player1Name?: string;
    player2Id?: string; // undefined = BYE
    player2Name?: string;
    winnerId?: string;
    winnerName?: string;
    score?: string;
    nextMatchId?: string; // Match al que avanza el ganador
    matchDate?: Date;
}

/**
 * Entidad de dominio que representa un cuadro de eliminación simple.
 */
export interface Bracket {
    id?: string;
    tournamentId: string;
    categoryId: string;
    matches: BracketMatch[];
    status: BracketStatus;
    createdAt?: Date;
    updatedAt?: Date;
}

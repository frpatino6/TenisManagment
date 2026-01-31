export type TournamentStatus = 'DRAFT' | 'IN_PROGRESS' | 'FINISHED' | 'CANCELLED';

export type CategoryGender = 'MALE' | 'FEMALE' | 'MIXED';

export type TournamentFormat = 'SINGLE_ELIMINATION' | 'ROUND_ROBIN' | 'HYBRID';

export interface GroupStageConfig {
    numberOfGroups: number;        // Ej: 4 grupos
    advancePerGroup: number;       // Ej: 2 mejores de cada grupo → 8 a cuartos
    pointsForWin: number;          // Ej: 3 puntos
    pointsForDraw: number;         // Ej: 1 punto (opcional en tenis)
    pointsForLoss: number;         // Ej: 0 puntos
    seedingMethod: 'RANKING' | 'RANDOM' | 'MANUAL'; // Por defecto: RANKING
}

export interface TournamentCategory {
    id: string;
    name: string;
    gender: CategoryGender;
    minElo?: number;
    maxElo?: number;
    participants: string[]; // User IDs

    // Configuración de formato
    format: TournamentFormat;

    // Configuración de fase de grupos (solo si format = 'HYBRID' o 'ROUND_ROBIN')
    groupStageConfig?: GroupStageConfig;

    // Referencias a las fases
    hasGroupStage?: boolean;
    hasBracket?: boolean;
}

/**
 * Entidad de dominio que representa un Torneo de Tenis.
 */
export interface Tournament {
    id?: string;
    tenantId: string;
    name: string;
    description: string;
    startDate: Date;
    endDate: Date;
    status: TournamentStatus;
    categories: TournamentCategory[];
    metadata?: Record<string, any>;
    createdAt?: Date;
    updatedAt?: Date;
}

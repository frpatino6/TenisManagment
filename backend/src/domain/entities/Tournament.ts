export type TournamentStatus = 'DRAFT' | 'IN_PROGRESS' | 'FINISHED' | 'CANCELLED';

export type CategoryGender = 'MALE' | 'FEMALE' | 'MIXED';

export interface TournamentCategory {
    id: string;
    name: string;
    gender: CategoryGender;
    minElo?: number;
    maxElo?: number;
    participants: string[]; // User IDs
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

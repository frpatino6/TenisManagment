/**
 * DTO para actualizar un torneo existente.
 * Todos los campos son opcionales para permitir actualizaciones parciales.
 */
export interface UpdateTournamentDto {
    name?: string;
    description?: string;
    startDate?: Date;
    endDate?: Date;
    registrationDeadline?: Date;
    location?: string;
    categories?: UpdateCategoryDto[];
}

/**
 * DTO para actualizar una categoría dentro de un torneo.
 */
export interface UpdateCategoryDto {
    /** ID de la categoría a actualizar (opcional para nuevas) */
    id?: string;
    name?: string;
    gender?: 'MALE' | 'FEMALE' | 'MIXED';
    format?: 'SINGLE_ELIMINATION' | 'HYBRID';
    minAge?: number;
    maxAge?: number;
    groupStageConfig?: {
        numberOfGroups: number;
        advancePerGroup: number;
        pointsForWin: number;
        pointsForDraw: number;
        pointsForLoss: number;
        seedingMethod: 'RANKING' | 'RANDOM';
    };
}

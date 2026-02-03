import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { UserRankingWithDetails } from '../../domain/entities/UserRanking';
import { Logger } from '../../infrastructure/services/Logger';

/**
 * Caso de uso para obtener los listados de ranking de un club.
 */
export class GetRankingsUseCase {
    private readonly logger = new Logger({ service: 'GetRankingsUseCase' });

    constructor(private readonly rankingRepository: IUserRankingRepository) { }

    /**
     * Obtiene los rankings para un club específico filtrados por tipo.
     * 
     * @param tenantId - ID del club (propietario de los datos).
     * @param type - Tipo de ranking solicitado ('elo' o 'race').
     * @param limit - Límite opcional de jugadores a retornar (default 50).
     * @returns Una promesa con la lista de rankings incluyendo detalles del usuario.
     */
    public async execute(tenantId: string, type: 'elo' | 'race', limit: number = 50): Promise<UserRankingWithDetails[]> {
        this.logger.info(`Obteniendo rankings de tipo ${type}`, { tenantId, limit });

        try {
            return this.rankingRepository.getRankingsWithUsers(tenantId, type, limit);
        } catch (error) {
            this.logger.error('Error al obtener rankings', { error, tenantId, type });
            throw error;
        }
    }
}


import { IUserRankingRepository } from '../../domain/repositories/IUserRankingRepository';
import { ProcessMatchResultUseCase, MatchResultData, MatchProcessResponse } from '../use-cases/ProcessMatchResultUseCase';
import { UserRanking, UserRankingWithDetails } from '../../domain/entities/UserRanking';
import { GetRankingsUseCase } from '../use-cases/GetRankingsUseCase';
import { Logger } from '../../infrastructure/services/Logger';

/**
 * Servicio encargado de la orquestación de operaciones relacionadas con el ranking de jugadores.
 * Implementa patrones de Clean Architecture delegando la lógica a casos de uso específicos.
 */
export class RankingService {
    private readonly logger = new Logger({ service: 'RankingService' });
    private readonly processMatchUseCase: ProcessMatchResultUseCase;
    private readonly getRankingsUseCase: GetRankingsUseCase;

    constructor(private readonly rankingRepository: IUserRankingRepository) {
        this.processMatchUseCase = new ProcessMatchResultUseCase(rankingRepository);
        this.getRankingsUseCase = new GetRankingsUseCase(rankingRepository);
    }


    /**
     * Obtiene el ranking para un club.
     * @param tenantId ID del club.
     * @param type Tipo de ranking ('elo' | 'race').
     */
    public async getRankings(tenantId: string, type: 'elo' | 'race'): Promise<UserRankingWithDetails[]> {
        return this.getRankingsUseCase.execute(tenantId, type);
    }

    /**
     * Procesa el resultado de un partido y actualiza los rankings de ambos jugadores.
     * @param matchData Datos del resultado del partido.
     * @returns Respuesta con los cambios en el ranking.
     */
    public async processMatchResult(matchData: MatchResultData): Promise<MatchProcessResponse> {
        return this.processMatchUseCase.execute(matchData);
    }

    /**
     * Obtiene los N jugadores con mayor ELO para el seeding de torneos.
     * 
     * @param tenantId - ID del club.
     * @param count - Cantidad de jugadores a obtener.
     * @returns Una promesa con la lista de los mejores jugadores por ELO.
     */
    public async getHeadsOfSeries(tenantId: string, count: number): Promise<UserRanking[]> {
        this.logger.info('Obteniendo cabezas de serie por ELO', { tenantId, count });
        return this.rankingRepository.getTopByElo(tenantId, count);
    }

    /**
     * Resetea los puntos de la carrera mensual (The Race) para todos los usuarios.
     * 
     * @param tenantId - ID opcional del club para reseteo específico.
     */
    public async resetMonthlyRace(tenantId?: string): Promise<void> {
        this.logger.info('Iniciando reseteo mensual de La Raza', { tenantId });
        try {
            await this.rankingRepository.resetMonthlyRace(tenantId);
            this.logger.info('Reseteo de La Raza completado exitosamente');
        } catch (error) {
            this.logger.error('Error al resetear La Raza mensual', { error, tenantId });
            throw error;
        }
    }
}



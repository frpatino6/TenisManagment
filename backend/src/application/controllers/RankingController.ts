import { Request, Response } from 'express';
import { RankingService } from '../services/RankingService';
import { Logger } from '../../infrastructure/services/Logger';

export class RankingController {
    private readonly logger = new Logger({ service: 'RankingController' });

    constructor(private readonly rankingService: RankingService) { }

    /**
     * GET /api/ranking/elo
     * Obtiene los rankings ordenados por ELO.
     */
    getEloRankings = async (req: Request, res: Response) => {
        try {
            const tenantId = req.tenantId;
            if (!tenantId) {
                return res.status(400).json({ error: 'X-Tenant-ID header is required' });
            }

            this.logger.info('Solicitando rankings ELO', { tenantId });
            const rankings = await this.rankingService.getRankings(tenantId, 'elo');
            return res.json(rankings);
        } catch (error) {
            this.logger.error('Error al obtener rankings ELO', {
                error: (error as Error).message,
                tenantId: req.tenantId
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * GET /api/ranking/race
     * Obtiene los rankings ordenados por puntos de The Race.
     */
    getRaceRankings = async (req: Request, res: Response) => {
        try {
            const tenantId = req.tenantId;
            if (!tenantId) {
                return res.status(400).json({ error: 'X-Tenant-ID header is required' });
            }

            this.logger.info('Solicitando rankings Race', { tenantId });
            const rankings = await this.rankingService.getRankings(tenantId, 'race');
            return res.json(rankings);
        } catch (error) {
            this.logger.error('Error al obtener rankings Race', {
                error: (error as Error).message,
                tenantId: req.tenantId
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };
}

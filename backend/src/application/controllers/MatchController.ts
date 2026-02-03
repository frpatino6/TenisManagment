import { Request, Response } from 'express';
import { RecordMatchResultUseCase, RecordMatchInput } from '../use-cases/RecordMatchResultUseCase';
import { Logger } from '../../infrastructure/services/Logger';

export class MatchController {
    private readonly logger = new Logger({ service: 'MatchController' });

    constructor(private readonly recordMatchUseCase: RecordMatchResultUseCase) { }

    /**
     * POST /api/matches
     * Registra un nuevo resultado de partido y actualiza rankings.
     */
    recordResult = async (req: Request, res: Response) => {
        try {
            const tenantId = req.tenantId;
            if (!tenantId) {
                return res.status(400).json({ error: 'X-Tenant-ID header is required' });
            }

            const { winnerId, loserId, score, isTournament, isOffPeak, isMatchmakingChallenge } = req.body;

            // Validación básica
            if (!winnerId || !loserId || !score) {
                return res.status(400).json({ error: 'winnerId, loserId and score are required' });
            }

            const input: RecordMatchInput = {
                tenantId,
                winnerId,
                loserId,
                score,
                isTournament: !!isTournament,
                isOffPeak: !!isOffPeak,
                isMatchmakingChallenge: !!isMatchmakingChallenge
            };

            this.logger.info('Solicitud para registrar partido recibida', { tenantId, winnerId, loserId });

            const result = await this.recordMatchUseCase.execute(input);

            return res.status(201).json(result);
        } catch (error) {
            this.logger.error('Error al registrar resultado de partido', {
                error: (error as Error).message,
                tenantId: req.tenantId
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };
}

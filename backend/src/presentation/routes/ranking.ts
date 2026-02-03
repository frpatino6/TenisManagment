import { Router } from 'express';
import { RankingController } from '../../application/controllers/RankingController';
import { RankingService } from '../../application/services/RankingService';
import { MongoUserRankingRepository } from '../../infrastructure/repositories/MongoUserRankingRepository';
import { extractTenantId } from '../../application/middleware/tenant';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();

// Inyección de dependencias
const repository = new MongoUserRankingRepository();
const service = new RankingService(repository);
const controller = new RankingController(service);

/**
 * @route GET /api/ranking/elo
 * @desc Obtener top jugadores por ELO
 * @access Private
 */
router.get('/elo', firebaseAuthMiddleware, extractTenantId, controller.getEloRankings);

/**
 * @route GET /api/ranking/race
 * @desc Obtener top jugadores por Monthly Race
 * @access Private
 */
router.get('/race', firebaseAuthMiddleware, extractTenantId, controller.getRaceRankings);

export default router;

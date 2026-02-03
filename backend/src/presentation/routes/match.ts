import { Router } from 'express';
import { MatchController } from '../../application/controllers/MatchController';
import { RecordMatchResultUseCase } from '../../application/use-cases/RecordMatchResultUseCase';
import { RankingService } from '../../application/services/RankingService';
import { MongoMatchRepository } from '../../infrastructure/repositories/MongoMatchRepository';
import { MongoUserRankingRepository } from '../../infrastructure/repositories/MongoUserRankingRepository';
import { extractTenantId } from '../../application/middleware/tenant';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();

// Inyección de dependencias
const matchRepository = new MongoMatchRepository();
const rankingRepository = new MongoUserRankingRepository();
const rankingService = new RankingService(rankingRepository);
const useCase = new RecordMatchResultUseCase(matchRepository, rankingService);
const controller = new MatchController(useCase);

/**
 * @route POST /api/matches
 * @desc Registrar resultado de partido
 * @access Private
 */
router.post('/', firebaseAuthMiddleware, extractTenantId, controller.recordResult);

export default router;

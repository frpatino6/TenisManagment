import { Router } from 'express';
import { TournamentController } from '../../application/controllers/TournamentController';
import { CreateTournamentUseCase } from '../../application/use-cases/CreateTournamentUseCase';
import { GetTournamentUseCase } from '../../application/use-cases/GetTournamentUseCase';
import { GenerateBracketUseCase } from '../../application/use-cases/GenerateBracketUseCase';
import { RecordTournamentMatchResultUseCase } from '../../application/use-cases/RecordTournamentMatchResultUseCase';
import { EnrollPlayerUseCase } from '../../application/use-cases/EnrollPlayerUseCase';
import { MongoTournamentRepository } from '../../infrastructure/repositories/MongoTournamentRepository';
import { MongoBracketRepository } from '../../infrastructure/repositories/MongoBracketRepository';
import { MongoUserRankingRepository } from '../../infrastructure/repositories/MongoUserRankingRepository';
import { BracketGenerationService } from '../../domain/services/BracketGenerationService';
import { RankingService } from '../../application/services/RankingService';
import { extractTenantId } from '../../application/middleware/tenant';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();

// Inyección de dependencias
const tournamentRepository = new MongoTournamentRepository();
const bracketRepository = new MongoBracketRepository();
const rankingRepository = new MongoUserRankingRepository();
const bracketGenerationService = new BracketGenerationService();
const rankingService = new RankingService(rankingRepository);

const createUseCase = new CreateTournamentUseCase(tournamentRepository);
const getTournamentUseCase = new GetTournamentUseCase(tournamentRepository);
const generateBracketUseCase = new GenerateBracketUseCase(
    tournamentRepository,
    bracketRepository,
    bracketGenerationService
);
const recordMatchResultUseCase = new RecordTournamentMatchResultUseCase(
    bracketRepository,
    tournamentRepository,
    rankingService
);
const enrollPlayerUseCase = new EnrollPlayerUseCase(tournamentRepository, bracketRepository);

const controller = new TournamentController(
    createUseCase,
    generateBracketUseCase,
    recordMatchResultUseCase,
    enrollPlayerUseCase,
    getTournamentUseCase,
    tournamentRepository,
    bracketRepository
);

/**
 * @route POST /api/tournaments
 * @desc Crear un nuevo torneo
 * @access Private
 */
router.post('/', firebaseAuthMiddleware, extractTenantId, controller.create);

/**
 * @route GET /api/tournaments
 * @desc Listar torneos del tenant
 * @access Private
 */
router.get('/', firebaseAuthMiddleware, extractTenantId, controller.list);

/**
 * @route GET /api/tournaments/:id
 * @desc Obtener detalles de un torneo
 * @access Private
 */
router.get('/:id', firebaseAuthMiddleware, extractTenantId, controller.getById);

/**
 * @route POST /api/tournaments/:id/categories/:categoryId/generate-bracket
 * @desc Generar bracket para una categoría
 * @access Private
 */
router.post(
    '/:id/categories/:categoryId/generate-bracket',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.generateBracket
);

/**
 * @route GET /api/tournaments/:id/categories/:categoryId/bracket
 * @desc Obtener bracket de una categoría
 * @access Private
 */
router.get(
    '/:id/categories/:categoryId/bracket',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.getBracket
);

/**
 * @route POST /api/tournaments/:id/matches/:matchId/result
 * @desc Registrar resultado de un partido de torneo
 * @access Private
 */
router.post(
    '/:id/matches/:matchId/result',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.recordMatchResult
);

/**
 * @route POST /api/tournaments/:id/categories/:categoryId/enroll
 * @desc Inscribir jugador en categoría
 * @access Private
 */
router.post(
    '/:id/categories/:categoryId/enroll',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.enroll
);

export default router;

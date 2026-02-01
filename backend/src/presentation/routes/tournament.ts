import { Router } from 'express';
import { TournamentController } from '../../application/controllers/TournamentController';
import { CreateTournamentUseCase } from '../../application/use-cases/CreateTournamentUseCase';
import { UpdateTournamentUseCase } from '../../application/use-cases/UpdateTournamentUseCase';
import { GetTournamentUseCase } from '../../application/use-cases/GetTournamentUseCase';
import { GenerateBracketUseCase } from '../../application/use-cases/GenerateBracketUseCase';
import { RecordTournamentMatchResultUseCase } from '../../application/use-cases/RecordTournamentMatchResultUseCase';
import { EnrollPlayerUseCase } from '../../application/use-cases/EnrollPlayerUseCase';
import { GenerateGroupsUseCase } from '../../application/use-cases/GenerateGroupsUseCase';
import { MoveParticipantBetweenGroupsUseCase } from '../../application/use-cases/MoveParticipantBetweenGroupsUseCase';
import { SwapParticipantsBetweenGroupsUseCase } from '../../application/use-cases/SwapParticipantsBetweenGroupsUseCase';
import { LockGroupsAndGenerateFixturesUseCase } from '../../application/use-cases/LockGroupsAndGenerateFixturesUseCase';
import { RecordGroupMatchResultUseCase } from '../../application/use-cases/RecordGroupMatchResultUseCase';
import { AdvanceToKnockoutPhaseUseCase } from '../../application/use-cases/AdvanceToKnockoutPhaseUseCase';
import { GetGroupStageUseCase } from '../../application/use-cases/GetGroupStageUseCase';
import { DeleteBracketUseCase } from '../../application/use-cases/DeleteBracketUseCase';
import { DeleteGroupStageUseCase } from '../../application/use-cases/DeleteGroupStageUseCase';
import { MongoTournamentRepository } from '../../infrastructure/repositories/MongoTournamentRepository';
import { MongoBracketRepository } from '../../infrastructure/repositories/MongoBracketRepository';
import { MongoUserRankingRepository } from '../../infrastructure/repositories/MongoUserRankingRepository';
import { MongoGroupStageRepository } from '../../infrastructure/database/repositories/MongoGroupStageRepository';
import { BracketGenerationService } from '../../domain/services/BracketGenerationService';
import { GroupStageGenerationService } from '../../domain/services/GroupStageGenerationService';
import { RankingService } from '../../application/services/RankingService';
import { extractTenantId } from '../../application/middleware/tenant';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();

// Inyección de dependencias
const tournamentRepository = new MongoTournamentRepository();
const bracketRepository = new MongoBracketRepository();
const rankingRepository = new MongoUserRankingRepository();
const rankingService = new RankingService(rankingRepository);
const bracketGenerationService = new BracketGenerationService();
const groupStageRepository = new MongoGroupStageRepository();
const groupStageGenerationService = new GroupStageGenerationService();

const createUseCase = new CreateTournamentUseCase(tournamentRepository);
const updateUseCase = new UpdateTournamentUseCase(tournamentRepository);
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

// Group stage use cases
const generateGroupsUseCase = new GenerateGroupsUseCase(
    tournamentRepository,
    groupStageRepository,
    rankingRepository,
    groupStageGenerationService
);
const moveParticipantBetweenGroupsUseCase = new MoveParticipantBetweenGroupsUseCase(
    groupStageRepository
);
const swapParticipantsBetweenGroupsUseCase = new SwapParticipantsBetweenGroupsUseCase(
    groupStageRepository
);
const lockGroupsAndGenerateFixturesUseCase = new LockGroupsAndGenerateFixturesUseCase(
    groupStageRepository,
    groupStageGenerationService
);
const recordGroupMatchResultUseCase = new RecordGroupMatchResultUseCase(
    groupStageRepository,
    groupStageGenerationService
);
const advanceToKnockoutPhaseUseCase = new AdvanceToKnockoutPhaseUseCase(
    groupStageRepository,
    tournamentRepository,
    bracketRepository,
    bracketGenerationService
);
const getGroupStageUseCase = new GetGroupStageUseCase(
    groupStageRepository
);
const deleteBracketUseCase = new DeleteBracketUseCase(tournamentRepository, bracketRepository);
const deleteGroupStageUseCase = new DeleteGroupStageUseCase(tournamentRepository, groupStageRepository);

const controller = new TournamentController(
    createUseCase,
    updateUseCase,
    generateBracketUseCase,
    recordMatchResultUseCase,
    enrollPlayerUseCase,
    getTournamentUseCase,
    tournamentRepository,
    bracketRepository,
    generateGroupsUseCase,
    moveParticipantBetweenGroupsUseCase,
    swapParticipantsBetweenGroupsUseCase,
    lockGroupsAndGenerateFixturesUseCase,
    recordGroupMatchResultUseCase,
    advanceToKnockoutPhaseUseCase,
    getGroupStageUseCase,
    deleteBracketUseCase,
    deleteGroupStageUseCase
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
 * @route PATCH /api/tournaments/:id
 * @desc Actualizar un torneo existente
 * @access Private
 */
router.patch('/:id', firebaseAuthMiddleware, extractTenantId, controller.update);

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

/**
 * @route POST /api/tournaments/:id/categories/:categoryId/generate-groups
 * @desc Generar grupos balanceados con snake seeding
 * @access Private
 */
router.post(
    '/:id/categories/:categoryId/generate-groups',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.generateGroups
);

/**
 * @route PUT /api/tournaments/:id/categories/:categoryId/groups/move-participant
 * @desc Mover participante entre grupos (drag & drop)
 * @access Private
 */
router.put(
    '/:id/categories/:categoryId/groups/move-participant',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.moveParticipantBetweenGroups
);

/**
 * @route PUT /api/tournaments/:id/categories/:categoryId/groups/swap-participants
 * @desc Intercambiar dos participantes entre grupos
 * @access Private
 */
router.put(
    '/:id/categories/:categoryId/groups/swap-participants',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.swapParticipantsBetweenGroups
);

/**
 * @route POST /api/tournaments/:id/categories/:categoryId/groups/lock
 * @desc Bloquear grupos y generar fixtures round robin
 * @access Private
 */
router.post(
    '/:id/categories/:categoryId/groups/lock',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.lockGroupsAndGenerateFixtures
);

/**
 * @route POST /api/tournaments/:id/categories/:categoryId/groups/matches/:matchId/result
 * @desc Registrar resultado de partido de grupo
 * @access Private
 */
router.post(
    '/:id/categories/:categoryId/groups/matches/:matchId/result',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.recordGroupMatchResult
);

/**
 * @route GET /api/tournaments/:id/categories/:categoryId/groups
 * @desc Obtener fase de grupos de una categoría
 * @access Private
 */
router.get(
    '/:id/categories/:categoryId/groups',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.getGroupStage
);

/**
 * @route POST /api/tournaments/:id/categories/:categoryId/advance-to-knockout
 * @desc Avanzar a fase de eliminación directa
 * @access Private
 */
router.post(
    '/:id/categories/:categoryId/advance-to-knockout',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.advanceToKnockoutPhase
);

/**
 * @route DELETE /api/tournaments/:id/categories/:categoryId/bracket
 * @desc Eliminar bracket de una categoría
 * @access Private
 */
router.delete(
    '/:id/categories/:categoryId/bracket',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.deleteBracket
);

/**
 * @route DELETE /api/tournaments/:id/categories/:categoryId/groups
 * @desc Eliminar fase de grupos de una categoría
 * @access Private
 */
router.delete(
    '/:id/categories/:categoryId/groups',
    firebaseAuthMiddleware,
    extractTenantId,
    controller.deleteGroupStage
);

export default router;

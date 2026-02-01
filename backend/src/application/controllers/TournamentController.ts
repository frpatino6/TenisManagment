import { Request, Response } from 'express';
import { CreateTournamentUseCase } from '../use-cases/CreateTournamentUseCase';
import { UpdateTournamentUseCase } from '../use-cases/UpdateTournamentUseCase';
import { GetTournamentUseCase } from '../use-cases/GetTournamentUseCase';
import { GenerateBracketUseCase } from '../use-cases/GenerateBracketUseCase';
import { RecordTournamentMatchResultUseCase } from '../use-cases/RecordTournamentMatchResultUseCase';
import { EnrollPlayerUseCase } from '../use-cases/EnrollPlayerUseCase';
import { GenerateGroupsUseCase } from '../use-cases/GenerateGroupsUseCase';
import { MoveParticipantBetweenGroupsUseCase } from '../use-cases/MoveParticipantBetweenGroupsUseCase';
import { SwapParticipantsBetweenGroupsUseCase } from '../use-cases/SwapParticipantsBetweenGroupsUseCase';
import { LockGroupsAndGenerateFixturesUseCase } from '../use-cases/LockGroupsAndGenerateFixturesUseCase';
import { RecordGroupMatchResultUseCase } from '../use-cases/RecordGroupMatchResultUseCase';
import { AdvanceToKnockoutPhaseUseCase } from '../use-cases/AdvanceToKnockoutPhaseUseCase';
import { GetGroupStageUseCase } from '../use-cases/GetGroupStageUseCase';
import { DeleteBracketUseCase } from '../use-cases/DeleteBracketUseCase';
import { DeleteGroupStageUseCase } from '../use-cases/DeleteGroupStageUseCase';
import { Logger } from '../../infrastructure/services/Logger';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';

export class TournamentController {
    private readonly logger = new Logger({ service: 'TournamentController' });

    constructor(
        private readonly createTournamentUseCase: CreateTournamentUseCase,
        private readonly updateTournamentUseCase: UpdateTournamentUseCase,
        private readonly generateBracketUseCase: GenerateBracketUseCase,
        private readonly recordMatchResultUseCase: RecordTournamentMatchResultUseCase,
        private readonly enrollPlayerUseCase: EnrollPlayerUseCase,
        private readonly getTournamentUseCase: GetTournamentUseCase,
        private readonly tournamentRepository: ITournamentRepository,
        private readonly bracketRepository: IBracketRepository,
        private readonly generateGroupsUseCase: GenerateGroupsUseCase,
        private readonly moveParticipantBetweenGroupsUseCase: MoveParticipantBetweenGroupsUseCase,
        private readonly swapParticipantsBetweenGroupsUseCase: SwapParticipantsBetweenGroupsUseCase,
        private readonly lockGroupsAndGenerateFixturesUseCase: LockGroupsAndGenerateFixturesUseCase,
        private readonly recordGroupMatchResultUseCase: RecordGroupMatchResultUseCase,
        private readonly advanceToKnockoutPhaseUseCase: AdvanceToKnockoutPhaseUseCase,
        private readonly getGroupStageUseCase: GetGroupStageUseCase,
        private readonly deleteBracketUseCase: DeleteBracketUseCase,
        private readonly deleteGroupStageUseCase: DeleteGroupStageUseCase
    ) { }

    /**
     * GET /api/tournaments/:id
     */
    getById = async (req: Request, res: Response) => {
        try {
            const { id } = req.params;
            const tournament = await this.getTournamentUseCase.execute(id);

            if (!tournament) {
                return res.status(404).json({ error: 'Torneo no encontrado' });
            }

            return res.json(tournament);
        } catch (error) {
            this.logger.error('Error al obtener torneo por ID', {
                error: (error as Error).message,
                tournamentId: req.params.id
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * POST /api/tournaments
     */
    create = async (req: Request, res: Response) => {
        try {
            const tenantId = req.tenantId;
            if (!tenantId) {
                return res.status(400).json({ error: 'X-Tenant-ID header is required' });
            }

            const { name, description, startDate, endDate, categories } = req.body;

            if (!name || !startDate || !endDate || !categories) {
                return res.status(400).json({ error: 'name, startDate, endDate and categories are required' });
            }

            const result = await this.createTournamentUseCase.execute({
                tenantId,
                name,
                description,
                startDate: new Date(startDate),
                endDate: new Date(endDate),
                categories
            });

            return res.status(201).json(result);
        } catch (error) {
            this.logger.error('Error al crear torneo', {
                error: (error as Error).message,
                tenantId: req.tenantId
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * GET /api/tournaments
     */
    list = async (req: Request, res: Response) => {
        try {
            const tenantId = req.tenantId;
            if (!tenantId) {
                return res.status(400).json({ error: 'X-Tenant-ID header is required' });
            }

            const tournaments = await this.tournamentRepository.findAllByTenant(tenantId);
            return res.json(tournaments);
        } catch (error) {
            this.logger.error('Error al listar torneos', {
                error: (error as Error).message,
                tenantId: req.tenantId
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * PATCH /api/tournaments/:id
     */
    update = async (req: Request, res: Response) => {
        try {
            const { id } = req.params;
            const tenantId = req.tenantId;

            if (!tenantId) {
                return res.status(400).json({ error: 'X-Tenant-ID header is required' });
            }

            const tournament = await this.updateTournamentUseCase.execute({
                tournamentId: id,
                tenantId,
                updateData: req.body,
            });

            return res.json(tournament);
        } catch (error) {
            this.logger.error('Error al actualizar torneo', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                tenantId: req.tenantId
            });

            // Errores de validación
            if ((error as Error).message.includes('No se puede cambiar el formato') ||
                (error as Error).message.includes('no encontrad') ||
                (error as Error).message.includes('No tiene permisos')) {
                return res.status(400).json({ error: (error as Error).message });
            }

            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * POST /api/tournaments/:id/categories/:categoryId/generate-bracket
     */
    generateBracket = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;

            const bracket = await this.generateBracketUseCase.execute(tournamentId, categoryId);
            return res.status(201).json(bracket);
        } catch (error) {
            this.logger.error('Error al generar bracket', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado') || message.includes('no existe')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('Ya existe')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * GET /api/tournaments/:id/categories/:categoryId/bracket
     */
    getBracket = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;

            const bracket = await this.bracketRepository.findByTournamentAndCategory(
                tournamentId,
                categoryId
            );

            if (!bracket) {
                return res.status(404).json({ error: 'Bracket no encontrado' });
            }

            return res.json(bracket);
        } catch (error) {
            this.logger.error('Error al obtener bracket', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId
            });
            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * POST /api/tournaments/:id/matches/:matchId/result
     */
    recordMatchResult = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, matchId } = req.params;
            const { winnerId, score } = req.body;

            if (!winnerId || !score) {
                return res.status(400).json({ error: 'winnerId y score son requeridos' });
            }

            const bracket = await this.recordMatchResultUseCase.execute({
                tournamentId,
                matchId,
                winnerId,
                score
            });

            return res.json(bracket);
        } catch (error) {
            this.logger.error('Error al registrar resultado', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                matchId: req.params.matchId
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('ya tiene un ganador')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * POST /api/tournaments/:id/categories/:categoryId/enroll
     */
    enroll = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;
            const firebaseUid = (req as any).user?.uid;

            if (!firebaseUid) {
                return res.status(401).json({ error: 'Usuario no autenticado' });
            }

            // Resolve student ID from firebase UID
            const authUser = await AuthUserModel.findOne({ firebaseUid });
            if (!authUser) {
                return res.status(404).json({ error: 'Usuario no encontrado' });
            }

            const student = await StudentModel.findOne({ authUserId: authUser._id });
            if (!student) {
                return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
            }

            await this.enrollPlayerUseCase.execute(tournamentId, categoryId, authUser._id.toString());
            return res.status(200).json({ message: 'Inscripción exitosa' });
        } catch (error) {
            this.logger.error('Error al inscribir jugador', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado') || message.includes('no existe')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('ya está inscrito')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * POST /api/tournaments/:id/categories/:categoryId/generate-groups
     * Genera grupos balanceados usando snake seeding basado en ELO
     */
    generateGroups = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;
            const config = req.body;

            const groupStage = await this.generateGroupsUseCase.execute({
                tournamentId,
                categoryId,
                config: Object.keys(config).length > 0 ? config : undefined
            });

            return res.status(201).json(groupStage);
        } catch (error) {
            this.logger.error('Error al generar grupos', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('ya existe')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * PUT /api/tournaments/:id/categories/:categoryId/groups/move-participant
     * Mueve un participante entre grupos (drag & drop)
     */
    moveParticipantBetweenGroups = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;
            const { participantId, fromGroupId, toGroupId } = req.body;

            if (!participantId || !fromGroupId || !toGroupId) {
                return res.status(400).json({
                    error: 'participantId, fromGroupId y toGroupId son requeridos',
                });
            }

            const groupStage = await this.moveParticipantBetweenGroupsUseCase.execute({
                tournamentId,
                categoryId,
                participantId,
                fromGroupId,
                toGroupId,
            });

            return res.json(groupStage);
        } catch (error) {
            this.logger.error('Error al mover participante entre grupos', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('estado DRAFT')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * PUT /api/tournaments/:id/categories/:categoryId/groups/swap-participants
     * Intercambia dos participantes entre grupos
     */
    swapParticipantsBetweenGroups = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;
            const { participant1Id, group1Id, participant2Id, group2Id } = req.body;

            if (!participant1Id || !group1Id || !participant2Id || !group2Id) {
                return res.status(400).json({
                    error: 'participant1Id, group1Id, participant2Id y group2Id son requeridos',
                });
            }

            const groupStage = await this.swapParticipantsBetweenGroupsUseCase.execute({
                tournamentId,
                categoryId,
                participant1Id,
                group1Id,
                participant2Id,
                group2Id,
            });

            return res.json(groupStage);
        } catch (error) {
            this.logger.error('Error al intercambiar participantes entre grupos', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('estado DRAFT')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * POST /api/tournaments/:id/categories/:categoryId/groups/lock
     * Bloquea grupos y genera fixtures round robin
     */
    lockGroupsAndGenerateFixtures = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;

            const groupStage = await this.lockGroupsAndGenerateFixturesUseCase.execute({
                tournamentId,
                categoryId,
            });

            return res.json(groupStage);
        } catch (error) {
            this.logger.error('Error al bloquear grupos', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('ya están bloqueados')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * POST /api/tournaments/:id/categories/:categoryId/groups/matches/:matchId/result
     * Registra el resultado de un partido de grupo
     */
    recordGroupMatchResult = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId, matchId } = req.params;
            const { winnerId, score } = req.body;

            if (!winnerId || !score) {
                return res.status(400).json({
                    error: 'winnerId y score son requeridos',
                });
            }

            const groupStage = await this.recordGroupMatchResultUseCase.execute({
                tournamentId,
                categoryId,
                matchId,
                winnerId,
                score,
            });

            return res.json(groupStage);
        } catch (error) {
            this.logger.error('Error al registrar resultado de partido de grupo', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
                matchId: req.params.matchId,
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * POST /api/tournaments/:id/categories/:categoryId/advance-to-knockout
     * Avanza a la fase de eliminación directa con los clasificados
     */
    advanceToKnockoutPhase = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;

            const bracket = await this.advanceToKnockoutPhaseUseCase.execute({
                tournamentId,
                categoryId,
            });

            return res.status(201).json(bracket);
        } catch (error) {
            this.logger.error('Error al avanzar a fase eliminatoria', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
            });

            const message = (error as Error).message;
            if (message.includes('no encontrado')) {
                return res.status(404).json({ error: message });
            }
            if (message.includes('no está completada')) {
                return res.status(409).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * GET /api/tournaments/:id/categories/:categoryId/groups
     * Obtiene el GroupStage de una categoría
     */
    getGroupStage = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;

            const groupStage = await this.getGroupStageUseCase.execute({
                tournamentId,
                categoryId,
            });

            if (!groupStage) {
                return res.status(404).json({ error: 'Fase de grupos no encontrada' });
            }

            return res.json(groupStage);
        } catch (error) {
            this.logger.error('Error al obtener fase de grupos', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId,
            });

            return res.status(500).json({ error: 'Error interno del servidor' });
        }
    };

    /**
     * DELETE /api/tournaments/:id/categories/:categoryId/bracket
     */
    deleteBracket = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;
            await this.deleteBracketUseCase.execute(tournamentId, categoryId);
            return res.status(204).send();
        } catch (error) {
            this.logger.error('Error al eliminar bracket', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId
            });

            const message = (error as Error).message;
            if (message.includes('No se puede eliminar')) {
                return res.status(409).json({ error: message });
            }
            if (message.includes('No existe')) {
                return res.status(404).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };

    /**
     * DELETE /api/tournaments/:id/categories/:categoryId/groups
     */
    deleteGroupStage = async (req: Request, res: Response) => {
        try {
            const { id: tournamentId, categoryId } = req.params;
            await this.deleteGroupStageUseCase.execute(tournamentId, categoryId);
            return res.status(204).send();
        } catch (error) {
            this.logger.error('Error al eliminar fase de grupos', {
                error: (error as Error).message,
                tournamentId: req.params.id,
                categoryId: req.params.categoryId
            });

            const message = (error as Error).message;
            if (message.includes('No se puede eliminar')) {
                return res.status(409).json({ error: message });
            }
            if (message.includes('No existe')) {
                return res.status(404).json({ error: message });
            }

            return res.status(400).json({ error: message });
        }
    };
}

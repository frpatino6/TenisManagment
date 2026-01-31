import { Request, Response } from 'express';
import { CreateTournamentUseCase } from '../use-cases/CreateTournamentUseCase';
import { GetTournamentUseCase } from '../use-cases/GetTournamentUseCase';
import { GenerateBracketUseCase } from '../use-cases/GenerateBracketUseCase';
import { RecordTournamentMatchResultUseCase } from '../use-cases/RecordTournamentMatchResultUseCase';
import { EnrollPlayerUseCase } from '../use-cases/EnrollPlayerUseCase';
import { Logger } from '../../infrastructure/services/Logger';
import { ITournamentRepository } from '../../domain/repositories/ITournamentRepository';
import { IBracketRepository } from '../../domain/repositories/IBracketRepository';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';

export class TournamentController {
    private readonly logger = new Logger({ service: 'TournamentController' });

    constructor(
        private readonly createTournamentUseCase: CreateTournamentUseCase,
        private readonly generateBracketUseCase: GenerateBracketUseCase,
        private readonly recordMatchResultUseCase: RecordTournamentMatchResultUseCase,
        private readonly enrollPlayerUseCase: EnrollPlayerUseCase,
        private readonly getTournamentUseCase: GetTournamentUseCase,
        private readonly tournamentRepository: ITournamentRepository,
        private readonly bracketRepository: IBracketRepository
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
}

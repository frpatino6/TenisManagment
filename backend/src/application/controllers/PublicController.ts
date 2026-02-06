import { Request, Response } from 'express';
import { MongoLeadRepository } from '../../infrastructure/repositories/MongoRepositories';
import { CreateLeadUseCase } from '../use-cases/CreateLeadUseCase';
import { LeadCreateSchema } from '../dtos/lead';
import { CalculatorLeadCreateSchema } from '../dtos/calculator-lead';
import { Logger } from '../../infrastructure/services/Logger';
import { EmailService } from '../../infrastructure/services/EmailService';
import { CalculatorLeadModel } from '../../infrastructure/database/models/CalculatorLeadModel';

/**
 * Controlador para operaciones públicas (sin autenticación).
 * Sigue el principio de delegación hacia casos de uso.
 */
export class PublicController {
    private readonly logger = new Logger({ context: 'PublicController' });
    private readonly createLeadUseCase: CreateLeadUseCase;
    private readonly emailService: EmailService;

    constructor() {
        // Inyección manual de dependencias
        const leadRepository = new MongoLeadRepository();
        this.createLeadUseCase = new CreateLeadUseCase(leadRepository);
        this.emailService = new EmailService();
    }

    /**
     * Crea un nuevo prospecto (lead) desde la landing page.
     * 
     * @param req - Request de Express
     * @param res - Response de Express
     */
    public async createLead(req: Request, res: Response): Promise<void> {
        try {
            this.logger.info('Recibida solicitud de nuevo lead en controlador');

            // Validar entrada con Zod
            const validatedData = LeadCreateSchema.parse(req.body);

            // Delegar al Caso de Uso
            const lead = await this.createLeadUseCase.execute(validatedData);

            this.logger.info('Lead procesado exitosamente', { leadId: lead.id });

            // Notificación por email de forma asíncrona (no bloquea la respuesta)
            this.emailService.sendDemoRequestNotification({
                clubName: validatedData.clubName,
                contactName: validatedData.contactName,
                email: validatedData.email,
                phone: validatedData.phone
            }).catch(err => {
                this.logger.error('Error asíncrono enviando notificación de lead', { error: err.message });
            });

            res.status(201).json({
                message: 'Lead registrado exitosamente',
                leadId: lead.id,
            });
        } catch (error: any) {
            if (error.name === 'ZodError') {
                res.status(400).json({
                    message: 'Error de validación',
                    errors: error.errors,
                });
                return;
            }

            this.logger.error('Error en PublicController.createLead', {
                error: error.message,
                stack: error.stack
            });

            res.status(500).json({ message: 'Error interno del servidor' });
        }
    }

    /**
     * Registra un lead de la Calculadora de Salud Financiera.
     */
    public async createCalculatorLead(req: Request, res: Response): Promise<void> {
        try {
            this.logger.info('Recibida solicitud de lead desde Calculadora de Salud Financiera');

            const validatedData = CalculatorLeadCreateSchema.parse(req.body);

            const lead = await CalculatorLeadModel.create(validatedData);

            this.logger.info('Calculator lead registrado', {
                leadId: lead._id,
                email: validatedData.email,
                monthlyLoss: validatedData.monthlyLoss
            });

            this.emailService.sendCalculatorLeadNotification(validatedData).catch(err => {
                this.logger.error('Error asíncrono enviando notificación de calculator lead', {
                    error: (err as Error).message
                });
            });

            res.status(201).json({
                message: 'Registro exitoso. Nos pondremos en contacto contigo pronto.',
                leadId: String(lead._id)
            });
        } catch (error: unknown) {
            const zodError = error as { name?: string; errors?: unknown[] };
            if (zodError?.name === 'ZodError' && Array.isArray(zodError.errors)) {
                res.status(400).json({
                    message: 'Error de validación',
                    errors: zodError.errors
                });
                return;
            }

            this.logger.error('Error en PublicController.createCalculatorLead', {
                error: error instanceof Error ? error.message : 'Unknown error'
            });

            res.status(500).json({ message: 'Error interno del servidor' });
        }
    }
}

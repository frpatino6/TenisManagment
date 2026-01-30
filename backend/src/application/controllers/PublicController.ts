import { Request, Response } from 'express';
import { MongoLeadRepository } from '../../infrastructure/repositories/MongoRepositories';
import { CreateLeadUseCase } from '../use-cases/CreateLeadUseCase';
import { LeadCreateSchema } from '../dtos/lead';
import { Logger } from '../../infrastructure/services/Logger';
import { EmailService } from '../../infrastructure/services/EmailService';

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
}

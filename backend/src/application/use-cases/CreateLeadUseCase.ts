import { Lead, LeadStatus } from '../../domain/entities/Lead';
import { LeadRepository } from '../../domain/repositories/index';
import { Logger } from '../../infrastructure/services/Logger';

export interface CreateLeadInput {
    clubName: string;
    contactName: string;
    email: string;
    phone: string;
}

/**
 * Caso de uso para registrar un nuevo interesado (lead).
 * Sigue los principios de Clean Architecture al desacoplar la lógica de negocio
 * de los adaptadores de entrada (Controladores) y salida (Repositorios).
 */
export class CreateLeadUseCase {
    private readonly logger = new Logger({ context: 'CreateLeadUseCase' });

    constructor(private readonly leadRepository: LeadRepository) { }

    /**
     * Ejecuta la lógica para crear un lead.
     * 
     * @param input - Datos del lead a crear
     * @returns La entidad Lead creada
     */
    public async execute(input: CreateLeadInput): Promise<Lead> {
        this.logger.info('Ejecutando caso de uso CreateLead', { email: input.email });

        // Verificar si ya existe un lead con ese email (opcional, según negocio)
        const existing = await this.leadRepository.findByEmail(input.email);
        if (existing) {
            this.logger.warn('Lead ya existe con este email', { email: input.email });
            // Aquí podríamos lanzar una excepción de dominio o simplemente actualizarlo
            // Por ahora, procedemos a crear uno nuevo o podríamos retornar el existente
        }

        const leadData: Omit<Lead, 'id' | 'createdAt' | 'updatedAt'> = {
            ...input,
            status: 'nuevo' as LeadStatus,
        };

        const lead = await this.leadRepository.create(leadData);

        this.logger.info('Lead creado exitosamente en el dominio', { leadId: lead.id });

        return lead;
    }
}

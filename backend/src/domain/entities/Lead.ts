export type LeadStatus = 'nuevo' | 'contactado' | 'descartado';

/**
 * Entidad de dominio que representa un interesado (Lead).
 * Definida como un POJO puro sin dependencias externas.
 */
export interface Lead {
    id?: string;
    clubName: string;
    contactName: string;
    email: string;
    phone: string;
    status: LeadStatus;
    createdAt?: Date;
    updatedAt?: Date;
}

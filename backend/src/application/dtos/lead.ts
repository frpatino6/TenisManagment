import { z } from 'zod';

export const LeadCreateSchema = z.object({
    clubName: z.string().min(3, 'El nombre del club debe tener al menos 3 caracteres'),
    contactName: z.string().min(3, 'El nombre de contacto debe tener al menos 3 caracteres'),
    email: z.string().email('Email inválido'),
    phone: z.string().regex(/^[0-9+ ]{9,15}$/, 'Formato de teléfono inválido'),
});

export type LeadCreateDto = z.infer<typeof LeadCreateSchema>;

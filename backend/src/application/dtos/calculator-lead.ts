import { z } from 'zod';

export const CalculatorLeadCreateSchema = z.object({
    clubName: z.string().min(3, 'El nombre del club debe tener al menos 3 caracteres'),
    email: z.string().email('Email inválido'),
    monthlyLoss: z.number().min(0),
    canchas: z.number().min(1).max(50),
    tarifa: z.number().min(1000).max(500000),
    cancelacionesSemanales: z.number().min(0).max(100),
    horasGestionManual: z.number().min(0).max(168),
});

export type CalculatorLeadCreateDto = z.infer<typeof CalculatorLeadCreateSchema>;

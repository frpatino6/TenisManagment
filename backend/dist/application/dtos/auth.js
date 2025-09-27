import { z } from 'zod';
export const RegisterSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
    role: z.enum(['professor', 'student']),
    profile: z.object({
        name: z.string().min(2),
        phone: z.string().min(5),
        specialties: z.array(z.string()).optional(),
        hourlyRate: z.number().optional(),
        membershipType: z.enum(['basic', 'premium']).optional()
    })
});
export const LoginSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6)
});
//# sourceMappingURL=auth.js.map
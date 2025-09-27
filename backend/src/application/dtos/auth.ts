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

export type RegisterDto = z.infer<typeof RegisterSchema>;
export type LoginDto = z.infer<typeof LoginSchema>;

export const PublishScheduleSchema = z.object({
  professorId: z.string().min(1),
  date: z.string().refine(v => !Number.isNaN(Date.parse(v)), { message: 'Invalid date' }).transform(v => new Date(v)),
  startTime: z.string().min(1),
  endTime: z.string().min(1),
  type: z.enum(['individual', 'group', 'court_rental']),
  isAvailable: z.boolean().optional(),
  maxStudents: z.number().int().positive().optional()
});

export const UpdateAvailabilitySchema = z.object({
  isAvailable: z.boolean()
});

export const BookLessonSchema = z.object({
  studentId: z.string().min(1),
  scheduleId: z.string().min(1),
  type: z.enum(['lesson', 'court_rental'])
});

export const ServiceCreateSchema = z.object({
  name: z.string().min(2),
  description: z.string().min(2),
  price: z.number().positive(),
  category: z.enum(['stringing', 'grip', 'other'])
});

export const ServiceUpdateSchema = ServiceCreateSchema.partial();

export const PaymentCreateSchema = z.object({
  studentId: z.string().min(1),
  professorId: z.string().min(1),
  amount: z.number().positive(),
  date: z.string().refine(v => !Number.isNaN(Date.parse(v)), { message: 'Invalid date' }).transform(v => new Date(v)),
  method: z.enum(['cash', 'card', 'transfer']),
  concept: z.string().min(2)
});


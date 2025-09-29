"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.RequestServiceSchema = exports.PaymentCreateSchema = exports.ServiceUpdateSchema = exports.ServiceCreateSchema = exports.BookLessonSchema = exports.UpdateAvailabilitySchema = exports.PublishScheduleSchema = exports.LoginSchema = exports.RegisterSchema = void 0;
const zod_1 = require("zod");
exports.RegisterSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6),
    role: zod_1.z.enum(['professor', 'student']),
    profile: zod_1.z.object({
        name: zod_1.z.string().min(2),
        phone: zod_1.z.string().min(5),
        specialties: zod_1.z.array(zod_1.z.string()).optional(),
        hourlyRate: zod_1.z.number().optional(),
        membershipType: zod_1.z.enum(['basic', 'premium']).optional()
    })
});
exports.LoginSchema = zod_1.z.object({
    email: zod_1.z.string().email(),
    password: zod_1.z.string().min(6)
});
exports.PublishScheduleSchema = zod_1.z.object({
    professorId: zod_1.z.string().min(1),
    date: zod_1.z.string().refine(v => !Number.isNaN(Date.parse(v)), { message: 'Invalid date' }).transform(v => new Date(v)),
    startTime: zod_1.z.string().min(1),
    endTime: zod_1.z.string().min(1),
    type: zod_1.z.enum(['individual', 'group', 'court_rental']),
    isAvailable: zod_1.z.boolean().optional(),
    maxStudents: zod_1.z.number().int().positive().optional()
});
exports.UpdateAvailabilitySchema = zod_1.z.object({
    isAvailable: zod_1.z.boolean()
});
exports.BookLessonSchema = zod_1.z.object({
    studentId: zod_1.z.string().min(1),
    scheduleId: zod_1.z.string().min(1),
    type: zod_1.z.enum(['lesson', 'court_rental'])
});
exports.ServiceCreateSchema = zod_1.z.object({
    name: zod_1.z.string().min(2),
    description: zod_1.z.string().min(2),
    price: zod_1.z.number().positive(),
    category: zod_1.z.enum(['stringing', 'grip', 'other'])
});
exports.ServiceUpdateSchema = exports.ServiceCreateSchema.partial();
exports.PaymentCreateSchema = zod_1.z.object({
    studentId: zod_1.z.string().min(1),
    professorId: zod_1.z.string().min(1),
    amount: zod_1.z.number().positive(),
    date: zod_1.z.string().refine(v => !Number.isNaN(Date.parse(v)), { message: 'Invalid date' }).transform(v => new Date(v)),
    method: zod_1.z.enum(['cash', 'card', 'transfer']),
    concept: zod_1.z.string().min(2)
});
exports.RequestServiceSchema = zod_1.z.object({
    studentId: zod_1.z.string().min(1),
    serviceId: zod_1.z.string().min(1),
    notes: zod_1.z.string().min(1).optional()
});
//# sourceMappingURL=auth.js.map
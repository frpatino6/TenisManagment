import { Router } from 'express';
import { ProfessorController } from '../../application/controllers/ProfessorController';
import { JwtService } from '../../infrastructure/services/JwtService';
import { authMiddleware, requireRole } from '../../application/middleware/auth';
import { validateBody } from '../../application/middleware/validation';
import { PublishScheduleSchema, UpdateAvailabilitySchema, ServiceCreateSchema, ServiceUpdateSchema, PaymentCreateSchema } from '../../application/dtos/auth';

const router = Router();
const jwt = new JwtService(process.env.JWT_SECRET || 'dev_secret');
const controller = new ProfessorController();

router.use(authMiddleware(jwt), requireRole('professor'));

router.get('/schedule', controller.getSchedule);
router.post('/schedule', validateBody(PublishScheduleSchema), controller.createSchedule);
router.put('/schedule/:id', validateBody(UpdateAvailabilitySchema), controller.updateSchedule);
router.delete('/schedule/:id', controller.deleteSchedule);
router.get('/income-report', controller.incomeReport);
router.get('/students', controller.listStudents);
router.post('/services', validateBody(ServiceCreateSchema), controller.createService);
router.put('/services/:id', validateBody(ServiceUpdateSchema), controller.updateService);
router.get('/services', controller.listServices);
router.delete('/services/:id', controller.deleteService);
router.post('/payments', validateBody(PaymentCreateSchema), controller.createPayment);

export default router;


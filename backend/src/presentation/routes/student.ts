import { Router } from 'express';
import { StudentController } from '../../application/controllers/StudentController';
import { JwtService } from '../../infrastructure/services/JwtService';
import { authMiddleware, requireRole } from '../../application/middleware/auth';
import { validateBody } from '../../application/middleware/validation';
import { BookLessonSchema, RequestServiceSchema } from '../../application/dtos/auth';

const router = Router();
const jwt = new JwtService(process.env.JWT_SECRET || 'dev_secret');
const controller = new StudentController();

router.use(authMiddleware(jwt), requireRole('student'));

router.get('/available-schedules', controller.availableSchedules);
router.post('/book-lesson', validateBody(BookLessonSchema), controller.book);
router.get('/bookings', controller.listBookings);
router.get('/balance', controller.getBalance);
router.get('/payment-history', controller.paymentHistoryList);
router.post('/request-service', validateBody(RequestServiceSchema), controller.requestService);

export default router;


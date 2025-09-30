import { Router } from 'express';
import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();
const controller = new StudentDashboardController();

// All routes use Firebase authentication
router.use(firebaseAuthMiddleware);

// Student dashboard endpoints
router.get('/activities', controller.getRecentActivities);
router.get('/me', controller.getStudentInfo);
router.get('/professors', controller.getProfessors);
router.get('/available-schedules', controller.getAvailableSchedules);
router.post('/book-lesson', controller.bookLesson);

export default router;

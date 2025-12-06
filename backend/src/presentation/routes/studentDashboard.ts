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
router.get('/available-schedules', controller.getAvailableSchedules); // Legacy endpoint
router.get('/professors/:professorId/schedules', controller.getProfessorSchedules); // TEN-90: Horarios agrupados por centro
router.get('/tenants/:tenantId/schedules', controller.getTenantSchedules); // TEN-90: Horarios de un centro
router.get('/all-available-schedules', controller.getAllAvailableSchedules); // TEN-90: Todos los horarios disponibles agrupados
router.get('/tenants', controller.getMyTenants); // TEN-91: Tenants del estudiante
router.get('/tenants/available', controller.getAvailableTenants); // TEN-93: Todos los centros disponibles
router.get('/bookings', controller.getBookings);
router.post('/book-lesson', controller.bookLesson);
router.post('/book-court', controller.bookCourt);

export default router;

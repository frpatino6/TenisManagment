import { Router } from 'express';
import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { extractTenantId } from '../../application/middleware/tenant';

const router = Router();
const controller = new StudentDashboardController();

// All routes use Firebase authentication
router.use(firebaseAuthMiddleware);
// Extract tenant ID from X-Tenant-ID header
router.use(extractTenantId);

// Student dashboard endpoints
router.get('/activities', controller.getRecentActivities);
router.get('/me', controller.getStudentInfo);
router.get('/professors', controller.getProfessors);
router.get('/available-schedules', controller.getAvailableSchedules); // Legacy endpoint
router.get('/professors/:professorId/schedules', controller.getProfessorSchedules); // TEN-90: Horarios agrupados por centro
router.get('/tenants/:tenantId/schedules', controller.getTenantSchedules); // TEN-90: Horarios de un centro
router.get('/all-available-schedules', controller.getAllAvailableSchedules); // TEN-90: Todos los horarios disponibles agrupados
router.get('/tenants', controller.getMyTenants); // TEN-91: Tenants del estudiante
router.get('/tenants/available', controller.getAvailableTenants); // TEN-91: Todos los centros disponibles
router.get('/courts', controller.getCourts); // TEN-96: Canchas disponibles del centro activo
router.get('/courts/:courtId/available-slots', controller.getCourtAvailableSlots); // Horarios disponibles de una cancha
router.get('/bookings', controller.getBookings);
router.post('/book-lesson', controller.bookLesson);
router.post('/book-court', controller.bookCourt);

// Preferences endpoints (TEN-95)
router.get('/preferences', controller.getPreferences);
router.post('/preferences/favorite-professor', controller.addFavoriteProfessor);
router.delete('/preferences/favorite-professor/:professorId', controller.removeFavoriteProfessor);
router.post('/preferences/favorite-tenant', controller.addFavoriteTenant);
router.delete('/preferences/favorite-tenant/:tenantId', controller.removeFavoriteTenant);

// Active Tenant endpoints
router.get('/active-tenant', controller.getActiveTenant);
router.post('/active-tenant', controller.setActiveTenant);

export default router;

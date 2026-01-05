import { Router } from 'express';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();
const professorDashboardController = new ProfessorDashboardController();

// Aplicar middleware de autenticación a todas las rutas
router.use(firebaseAuthMiddleware);

// Obtener información del profesor
router.get('/me', professorDashboardController.getProfessorInfo);

// Obtener lista de estudiantes
router.get('/students', professorDashboardController.getStudents);

// Obtener horarios por fecha específica
router.get('/schedule/by-date', professorDashboardController.getScheduleByDate);

// Obtener horarios de hoy
router.get('/schedule/today', professorDashboardController.getTodaySchedule);

// Obtener horarios de la semana
router.get('/schedule/week', professorDashboardController.getWeekSchedule);

// Obtener estadísticas de ganancias
router.get('/earnings', professorDashboardController.getEarningsStats);

// Obtener tenants del profesor
router.get('/tenants', professorDashboardController.getMyTenants); // TEN-91: Tenants del profesor

// Unirse a un centro (self-service)
// TODO: TEN-108 - This will change when tenant admin module is implemented
router.post('/tenants/join', professorDashboardController.joinTenant);

// Actualizar perfil del profesor
router.put('/profile', professorDashboardController.updateProfile);

// Confirmar clase
router.put('/schedule/:classId/confirm', professorDashboardController.confirmClass);

// Cancelar clase
router.put('/schedule/:classId/cancel', professorDashboardController.cancelClass);

// Create a new schedule
router.post('/schedules', professorDashboardController.createSchedule);

// Get all schedules for the professor
router.get('/schedules', professorDashboardController.getMySchedules);

// Delete a schedule
router.delete('/schedules/:scheduleId', professorDashboardController.deleteSchedule);

// Block a schedule
router.put('/schedules/:scheduleId/block', professorDashboardController.blockSchedule);

// Unblock a schedule
router.put('/schedules/:scheduleId/unblock', professorDashboardController.unblockSchedule);

// Complete a class
router.put('/schedules/:scheduleId/complete', professorDashboardController.completeClass);

// Cancel a booking
router.put('/schedules/:scheduleId/cancel-booking', professorDashboardController.cancelBooking);

export default router;

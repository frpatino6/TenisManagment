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

// Obtener horarios de hoy
router.get('/schedule/today', professorDashboardController.getTodaySchedule);

// Obtener horarios de la semana
router.get('/schedule/week', professorDashboardController.getWeekSchedule);

// Obtener estadísticas de ganancias
router.get('/earnings', professorDashboardController.getEarningsStats);

// Actualizar perfil del profesor
router.put('/profile', professorDashboardController.updateProfile);

// Confirmar clase
router.put('/schedule/:classId/confirm', professorDashboardController.confirmClass);

// Cancelar clase
router.put('/schedule/:classId/cancel', professorDashboardController.cancelClass);

export default router;

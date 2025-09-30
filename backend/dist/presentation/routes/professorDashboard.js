"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const ProfessorDashboardController_1 = require("../../application/controllers/ProfessorDashboardController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const router = (0, express_1.Router)();
const professorDashboardController = new ProfessorDashboardController_1.ProfessorDashboardController();
// Aplicar middleware de autenticación a todas las rutas
router.use(firebaseAuth_1.firebaseAuthMiddleware);
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
exports.default = router;
//# sourceMappingURL=professorDashboard.js.map
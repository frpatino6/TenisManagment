"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const StudentDashboardController_1 = require("../../application/controllers/StudentDashboardController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const router = (0, express_1.Router)();
const controller = new StudentDashboardController_1.StudentDashboardController();
// All routes use Firebase authentication
router.use(firebaseAuth_1.firebaseAuthMiddleware);
// Student dashboard endpoints
router.get('/activities', controller.getRecentActivities);
router.get('/me', controller.getStudentInfo);
router.get('/professors', controller.getProfessors);
router.get('/available-schedules', controller.getAvailableSchedules); // Legacy endpoint
router.get('/professors/:professorId/schedules', controller.getProfessorSchedules); // TEN-90: Horarios agrupados por centro
router.get('/tenants/:tenantId/schedules', controller.getTenantSchedules); // TEN-90: Horarios de un centro
router.get('/all-available-schedules', controller.getAllAvailableSchedules); // TEN-90: Todos los horarios disponibles agrupados
router.get('/tenants', controller.getMyTenants); // TEN-91: Tenants del estudiante
router.get('/bookings', controller.getBookings);
router.post('/book-lesson', controller.bookLesson);
router.post('/book-court', controller.bookCourt);
// Preferences endpoints (TEN-95)
router.get('/preferences', controller.getPreferences);
router.post('/preferences/favorite-professor', controller.addFavoriteProfessor);
router.delete('/preferences/favorite-professor/:professorId', controller.removeFavoriteProfessor);
router.post('/preferences/favorite-tenant', controller.addFavoriteTenant);
router.delete('/preferences/favorite-tenant/:tenantId', controller.removeFavoriteTenant);
exports.default = router;
//# sourceMappingURL=studentDashboard.js.map
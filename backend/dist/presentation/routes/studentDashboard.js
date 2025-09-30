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
router.get('/available-schedules', controller.getAvailableSchedules);
router.post('/book-lesson', controller.bookLesson);
exports.default = router;
//# sourceMappingURL=studentDashboard.js.map
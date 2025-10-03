"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const AnalyticsController_1 = require("../../application/controllers/AnalyticsController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const auth_1 = require("../../application/middleware/auth");
const router = (0, express_1.Router)();
const controller = new AnalyticsController_1.AnalyticsController();
// Todas las rutas en este router usarán el middleware de Firebase Auth y requerirán rol de profesor
router.use(firebaseAuth_1.firebaseAuthMiddleware, (0, auth_1.requireRole)('professor'));
// Analytics overview endpoint
router.get('/overview', controller.getOverview);
// Individual chart data endpoints
router.get('/revenue', controller.getRevenueData);
router.get('/bookings', controller.getBookingsData);
router.get('/students', controller.getStudentsData);
// Breakdown data endpoints
router.get('/revenue/breakdown', controller.getRevenueBreakdown);
router.get('/bookings/breakdown', controller.getBookingsBreakdown);
// Trend data endpoints
router.get('/revenue/trend', controller.getRevenueTrend);
router.get('/bookings/trend', controller.getBookingsTrend);
// Students data endpoints
router.get('/students/breakdown', controller.getStudentsBreakdown);
router.get('/students/trend', controller.getStudentsTrend);
exports.default = router;
//# sourceMappingURL=analytics.js.map
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
exports.default = router;
//# sourceMappingURL=analytics.js.map
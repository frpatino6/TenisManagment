"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const AnalyticsController_1 = require("../../application/controllers/AnalyticsController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const auth_1 = require("../../application/middleware/auth");
const analyticsValidation_1 = require("../../application/middleware/analyticsValidation");
const router = (0, express_1.Router)();
const controller = new AnalyticsController_1.AnalyticsController();
// Apply common middleware to all routes
router.use(firebaseAuth_1.firebaseAuthMiddleware, (0, auth_1.requireRole)('professor'), analyticsValidation_1.rateLimitAnalytics, analyticsValidation_1.sanitizeQueryParams, analyticsValidation_1.validateAnalyticsQuery);
// Analytics overview endpoint
router.get('/overview', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, controller.getOverview);
// Individual chart data endpoints
router.get('/revenue', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validatePaymentStatus, controller.getRevenueData);
router.get('/bookings', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, controller.getBookingsData);
router.get('/students', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, controller.getStudentsData);
// Breakdown data endpoints
router.get('/revenue/breakdown', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validatePaymentStatus, analyticsValidation_1.validateDateRange, controller.getRevenueBreakdown);
router.get('/bookings/breakdown', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, analyticsValidation_1.validateDateRange, controller.getBookingsBreakdown);
// Trend data endpoints
router.get('/revenue/trend', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validatePaymentStatus, analyticsValidation_1.validateDateRange, controller.getRevenueTrend);
router.get('/bookings/trend', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, analyticsValidation_1.validateDateRange, controller.getBookingsTrend);
// Students data endpoints
router.get('/students/breakdown', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, analyticsValidation_1.validateDateRange, controller.getStudentsBreakdown);
router.get('/students/trend', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateServiceType, analyticsValidation_1.validateBookingStatus, analyticsValidation_1.validateDateRange, controller.getStudentsTrend);
// Occupancy data endpoints
router.get('/occupancy/details', analyticsValidation_1.validatePeriod, analyticsValidation_1.validateDateRange, controller.getOccupancyDetails);
exports.default = router;
//# sourceMappingURL=analytics.js.map
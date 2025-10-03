import { Router } from 'express';
import { AnalyticsController } from '../../application/controllers/AnalyticsController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { requireRole } from '../../application/middleware/auth';

const router = Router();
const controller = new AnalyticsController();

// Todas las rutas en este router usarán el middleware de Firebase Auth y requerirán rol de profesor
router.use(firebaseAuthMiddleware, requireRole('professor'));

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

export default router;

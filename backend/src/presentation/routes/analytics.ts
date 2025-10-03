import { Router } from 'express';
import { AnalyticsController } from '../../application/controllers/AnalyticsController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { requireRole } from '../../application/middleware/auth';
import {
  validateAnalyticsQuery,
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  validatePaymentStatus,
  validateDateRange,
  validatePagination,
  validateSort,
  sanitizeQueryParams,
  rateLimitAnalytics,
} from '../../application/middleware/analyticsValidation';

const router = Router();
const controller = new AnalyticsController();

// Apply common middleware to all routes
router.use(
  firebaseAuthMiddleware,
  requireRole('professor'),
  rateLimitAnalytics,
  sanitizeQueryParams,
  validateAnalyticsQuery,
);

// Analytics overview endpoint
router.get('/overview', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  controller.getOverview
);

// Individual chart data endpoints
router.get('/revenue', 
  validatePeriod,
  validateServiceType,
  validatePaymentStatus,
  controller.getRevenueData
);

router.get('/bookings', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  controller.getBookingsData
);

router.get('/students', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  controller.getStudentsData
);

// Breakdown data endpoints
router.get('/revenue/breakdown', 
  validatePeriod,
  validateServiceType,
  validatePaymentStatus,
  validateDateRange,
  controller.getRevenueBreakdown
);

router.get('/bookings/breakdown', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  validateDateRange,
  controller.getBookingsBreakdown
);

// Trend data endpoints
router.get('/revenue/trend', 
  validatePeriod,
  validateServiceType,
  validatePaymentStatus,
  validateDateRange,
  controller.getRevenueTrend
);

router.get('/bookings/trend', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  validateDateRange,
  controller.getBookingsTrend
);

// Students data endpoints
router.get('/students/breakdown', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  validateDateRange,
  controller.getStudentsBreakdown
);

router.get('/students/trend', 
  validatePeriod,
  validateServiceType,
  validateBookingStatus,
  validateDateRange,
  controller.getStudentsTrend
);

// Occupancy data endpoints
router.get('/occupancy/details', 
  validatePeriod,
  validateDateRange,
  controller.getOccupancyDetails
);

export default router;

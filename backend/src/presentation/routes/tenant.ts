/**
 * Tenant Routes - Tenant Admin Endpoints
 * TEN-88: MT-BACK-006
 *
 * Rutas para que Tenant Admin gestione su centro
 */

import { Router } from 'express';
import { TenantAdminController } from '../../application/controllers/TenantAdminController';
import { TenantService } from '../../application/services/TenantService';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { requireRole } from '../../application/middleware/auth';
import { extractTenantId, requireTenantAccess } from '../../application/middleware/tenant';

const router = Router();
const tenantService = new TenantService();
const controller = new TenantAdminController(tenantService);

// Todas las rutas requieren autenticación Firebase y rol tenant_admin
router.use(firebaseAuthMiddleware);
router.use(requireRole('tenant_admin'));

// GET /me no requiere X-Tenant-ID porque obtiene el tenant directamente del admin
router.get('/me', controller.getTenantInfo);

// Las demás rutas requieren X-Tenant-ID header
router.use(extractTenantId);
router.use(requireTenantAccess(tenantService));

// Configuración del centro
router.put('/me', controller.updateTenantConfig);
router.put('/operating-hours', controller.updateOperatingHours);

// Gestión de profesores
router.get('/professors', controller.listProfessors);
router.post('/professors/invite', controller.inviteProfessor);
router.patch('/professors/:id/activate', controller.activateProfessor);
router.patch('/professors/:id/deactivate', controller.deactivateProfessor);
router.put('/professors/:id', controller.updateProfessor);

// Gestión de canchas
router.get('/courts', controller.listCourts);
router.post('/courts', controller.createCourt);
router.put('/courts/:id', controller.updateCourt);
router.delete('/courts/:id', controller.deleteCourt);

// Gestión de pagos (transacciones)
router.get('/payments', controller.listPayments);
router.patch('/payments/:id/confirm', controller.confirmManualPayment);

// Métricas y reportes del centro
router.get('/metrics', controller.getMetrics);
router.get('/analytics/overview', controller.getAnalyticsOverview);
router.get('/reports/debts', controller.getDebtReport);

// Gestión de reservas
router.get('/bookings', controller.listBookings);
router.get('/bookings/calendar', controller.getBookingCalendar);
router.get('/bookings/stats', controller.getBookingStats);
router.get('/bookings/:id', controller.getBookingDetails);
router.patch('/bookings/:id/cancel', controller.cancelBooking);

// Gestión de estudiantes
router.get('/students', controller.listStudents);
router.get('/students/:id', controller.getStudentDetails);
router.patch('/students/:id/balance', controller.updateStudentBalance);

export default router;


/**
 * Tenant Routes - Tenant Admin Endpoints
 * TEN-88: MT-BACK-006
 *
 * Rutas para que Tenant Admin gestione su centro
 */

import { Router } from 'express';
import { TenantAdminController } from '../../application/controllers/TenantAdminController';
import { TenantService } from '../../application/services/TenantService';
import { authMiddleware } from '../../application/middleware/auth';
import { requireRole } from '../../application/middleware/auth';
import { extractTenantId, requireTenantAccess } from '../../application/middleware/tenant';
import { JwtService } from '../../infrastructure/services/JwtService';
import { config } from '../../infrastructure/config';

const router = Router();
const jwtService = new JwtService(config.jwtSecret);
const tenantService = new TenantService();
const controller = new TenantAdminController(tenantService);

// Todas las rutas requieren autenticación y rol tenant_admin
router.use(authMiddleware(jwtService));
router.use(requireRole('tenant_admin'));

// GET /me no requiere X-Tenant-ID porque obtiene el tenant directamente del admin
router.get('/me', controller.getTenantInfo);

// Las demás rutas requieren X-Tenant-ID header
router.use(extractTenantId);
router.use(requireTenantAccess(tenantService));
router.put('/me', controller.updateTenantConfig);
router.put('/operating-hours', controller.updateOperatingHours);

// Gestión de profesores
router.get('/professors', controller.listProfessors);
router.post('/professors/invite', controller.inviteProfessor);
router.patch('/professors/:id/activate', controller.activateProfessor);
router.patch('/professors/:id/deactivate', controller.deactivateProfessor);

// Gestión de canchas
router.get('/courts', controller.listCourts);
router.post('/courts', controller.createCourt);
router.put('/courts/:id', controller.updateCourt);
router.delete('/courts/:id', controller.deleteCourt);

// Métricas del centro
router.get('/metrics', controller.getMetrics);

export default router;


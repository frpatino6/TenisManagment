/**
 * Admin Routes - Super Admin Endpoints
 * TEN-87: MT-BACK-005
 *
 * Rutas para que Super Admin gestione tenants
 */

import { Router } from 'express';
import { SuperAdminController } from '../../application/controllers/SuperAdminController';
import { TenantService } from '../../application/services/TenantService';
import { authMiddleware } from '../../application/middleware/auth';
import { requireSuperAdmin } from '../../application/middleware/auth';
import { JwtService } from '../../infrastructure/services/JwtService';
import { config } from '../../infrastructure/config';

const router = Router();
const jwtService = new JwtService(config.jwtSecret);
const tenantService = new TenantService();
const controller = new SuperAdminController(tenantService);

// Todas las rutas requieren autenticación y rol de Super Admin
router.use(authMiddleware(jwtService));
router.use(requireSuperAdmin);

// CRUD de tenants
router.post('/tenants', controller.createTenant);
router.get('/tenants', controller.listTenants);
router.get('/tenants/:id', controller.getTenant);
router.put('/tenants/:id', controller.updateTenant);
router.patch('/tenants/:id/activate', controller.activateTenant);
router.patch('/tenants/:id/deactivate', controller.deactivateTenant);

// Métricas globales
router.get('/metrics', controller.getGlobalMetrics);

export default router;

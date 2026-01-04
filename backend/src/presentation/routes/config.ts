import { Router } from 'express';
import { SystemConfigController } from '../../application/controllers/SystemConfigController';

const router = Router();
const controller = new SystemConfigController();

// Endpoint público para obtener información de versión
router.get('/version', controller.getVersionInfo);

// Endpoint público para obtener tenants activos (usado en registro)
router.get('/tenants/public', controller.getPublicTenants);

export default router;


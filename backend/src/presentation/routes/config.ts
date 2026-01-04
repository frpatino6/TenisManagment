import { Router } from 'express';
import { SystemConfigController } from '../../application/controllers/SystemConfigController';

const router = Router();
const controller = new SystemConfigController();

// Endpoint público para obtener información de versión
router.get('/version', controller.getVersionInfo);

export default router;


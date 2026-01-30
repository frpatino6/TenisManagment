import { Router } from 'express';
import { PublicController } from '../../application/controllers/PublicController';

const router = Router();
const publicController = new PublicController();

/**
 * Rutas públicas que no requieren autenticación.
 */
router.post('/leads', (req, res) => publicController.createLead(req, res));

export default router;

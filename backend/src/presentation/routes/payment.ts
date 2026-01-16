import { Router } from 'express';
import { PaymentController } from '../../application/controllers/PaymentController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { extractTenantId } from '../../application/middleware/tenant';

const router = Router();
const controller = new PaymentController();

// Inicializar pago (Usuario autenticado con Firebase)
router.post('/init', firebaseAuthMiddleware, extractTenantId, controller.initPayment);

// Webhook Wompi
router.post('/webhooks/wompi', controller.wompiWebhook);
router.get('/webhooks/wompi', (_req, res) => res.status(200).json({ status: 'ok' }));

export default router;

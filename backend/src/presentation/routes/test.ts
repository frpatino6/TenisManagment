
import { Router } from 'express';
import { TestController } from '../../application/controllers/TestController';

const router = Router();
const controller = new TestController();

// Este router solo será montado en desarrollo
router.post('/simulate-wompi-payment', controller.simulateWompiPayment);

export default router;

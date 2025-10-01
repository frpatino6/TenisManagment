import { Router } from 'express';
import { PricingController } from '../../application/controllers/PricingController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();
const pricingController = new PricingController();

// Public routes
router.get('/base', pricingController.getBasePricing);
router.post('/initialize', pricingController.initializeBasePricing); // Call once to setup
router.get('/professor/:professorId', pricingController.getProfessorPricing);

// Protected routes (requires authentication)
router.get('/my-pricing', firebaseAuthMiddleware, pricingController.getMyPricing);
router.put('/my-pricing', firebaseAuthMiddleware, pricingController.updateMyPricing);
router.delete('/my-pricing', firebaseAuthMiddleware, pricingController.resetMyPricing);

export default router;


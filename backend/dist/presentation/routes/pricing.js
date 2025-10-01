"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = require("express");
const PricingController_1 = require("../../application/controllers/PricingController");
const firebaseAuth_1 = require("../../application/middleware/firebaseAuth");
const router = (0, express_1.Router)();
const pricingController = new PricingController_1.PricingController();
// Public routes
router.get('/base', pricingController.getBasePricing);
router.get('/professor/:professorId', pricingController.getProfessorPricing);
// Protected routes (requires authentication)
router.get('/my-pricing', firebaseAuth_1.firebaseAuthMiddleware, pricingController.getMyPricing);
router.put('/my-pricing', firebaseAuth_1.firebaseAuthMiddleware, pricingController.updateMyPricing);
router.delete('/my-pricing', firebaseAuth_1.firebaseAuthMiddleware, pricingController.resetMyPricing);
exports.default = router;
//# sourceMappingURL=pricing.js.map
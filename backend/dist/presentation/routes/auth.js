import { Router } from 'express';
import { AuthController } from '../../application/controllers/AuthController.js';
import { JwtService } from '../../infrastructure/services/JwtService.js';
const router = Router();
const jwt = new JwtService(process.env.JWT_SECRET || 'dev_secret');
const controller = new AuthController(jwt);
router.post('/login', controller.login);
router.post('/register', controller.register);
router.post('/refresh', controller.refresh);
export default router;
//# sourceMappingURL=auth.js.map
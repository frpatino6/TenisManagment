import { Router } from 'express';
import { AuthController } from '../../application/controllers/AuthController.js';
import { JwtService } from '../../infrastructure/services/JwtService.js';
import { validateBody } from '../../application/middleware/validation.js';
import { LoginSchema, RegisterSchema } from '../../application/dtos/auth.js';

const router = Router();
const jwt = new JwtService(process.env.JWT_SECRET || 'dev_secret');
const controller = new AuthController(jwt);

router.post('/login', validateBody(LoginSchema), controller.login);
router.post('/register', validateBody(RegisterSchema), controller.register);
router.post('/refresh', controller.refresh);

export default router;


import { Router } from 'express';
import { AuthController } from '../../application/controllers/AuthController';
import { JwtService } from '../../infrastructure/services/JwtService';
import { validateBody } from '../../application/middleware/validation';
import { LoginSchema, RegisterSchema } from '../../application/dtos/auth';
import { config } from '../../infrastructure/config';
import rateLimit from 'express-rate-limit';

const router = Router();
const jwt = new JwtService(config.jwtSecret);
const controller = new AuthController(jwt);

// Stricter rate limit for auth endpoints
const authLimiter = rateLimit({
  windowMs: config.http.rateLimit.windowMs,
  max: config.http.rateLimit.authMax,
});
router.use(authLimiter);

router.post('/login', validateBody(LoginSchema), controller.login);
router.post('/register', validateBody(RegisterSchema), controller.register);
router.post('/refresh', controller.refresh);

export default router;

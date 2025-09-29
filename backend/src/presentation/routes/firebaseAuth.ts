import { Router } from 'express';
import { FirebaseAuthController } from '../../application/controllers/FirebaseAuthController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

const router = Router();
const firebaseAuthController = new FirebaseAuthController();

// Verificar token de Firebase
router.post('/verify', firebaseAuthController.verifyToken);

// Registrar usuario con email/contraseña
router.post('/register', firebaseAuthController.registerUser);

// Obtener información del usuario autenticado
router.get('/me', firebaseAuthMiddleware, firebaseAuthController.getMe);

export default router;

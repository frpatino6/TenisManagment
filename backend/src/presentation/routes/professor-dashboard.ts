import { Router } from 'express';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';
import { ProfessorController } from '../../application/controllers/ProfessorController';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { config } from '../../infrastructure/config';

const router = Router();
const professorDashboardController = new ProfessorDashboardController();
const professorController = new ProfessorController();

// Middleware para verificar autenticación con Firebase
router.use(firebaseAuthMiddleware);

// Rutas del dashboard del profesor
router.get('/me', professorDashboardController.getProfessorInfo);
router.put('/profile', professorDashboardController.updateProfile);
router.get('/students', professorController.listStudents);

export default router;

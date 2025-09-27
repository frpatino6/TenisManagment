import { Router } from 'express';
import { ProfessorController } from '../../application/controllers/ProfessorController.js';
import { JwtService } from '../../infrastructure/services/JwtService.js';
import { authMiddleware, requireRole } from '../../application/middleware/auth.js';
const router = Router();
const jwt = new JwtService(process.env.JWT_SECRET || 'dev_secret');
const controller = new ProfessorController();
router.use(authMiddleware(jwt), requireRole('professor'));
router.get('/schedule', controller.getSchedule);
router.post('/schedule', controller.createSchedule);
router.put('/schedule/:id', controller.updateSchedule);
router.delete('/schedule/:id', controller.deleteSchedule);
router.get('/income-report', controller.incomeReport);
router.post('/services', controller.createService);
router.put('/services/:id', controller.updateService);
export default router;
//# sourceMappingURL=professor.js.map
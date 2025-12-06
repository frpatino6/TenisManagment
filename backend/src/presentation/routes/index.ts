import { Router } from 'express';
import auth from './auth';
import professor from './professor';
import professorDashboard from './professor-dashboard';
import analytics from './analytics';
import student from './student';
import pricing from './pricing';
import admin from './admin';

const router = Router();

// Placeholder routers to be mounted later
router.get('/', (_req, res) => {
  res.json({ message: 'API ready' });
});

router.use('/auth', auth);
router.use('/professor', professor);
router.use('/professor-dashboard', professorDashboard);
router.use('/professor-dashboard/analytics', analytics);
router.use('/student', student);
router.use('/pricing', pricing);
router.use('/admin', admin);

export default router;

import { Router } from 'express';
import auth from './auth';
import professor from './professor';
import professorDashboard from './professor-dashboard';
import analytics from './analytics';
import student from './student';
import pricing from './pricing';
import admin from './admin';
import tenant from './tenant';
import config from './config';
import payment from './payment';
import test from './test';

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
router.use('/tenant', tenant);
router.use('/config', config);
router.use('/payments', payment);
router.use('/test', test);

export default router;

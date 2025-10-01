import { Router } from 'express';
import auth from './auth';
import professor from './professor';
import student from './student';
import pricing from './pricing';

const router = Router();

// Placeholder routers to be mounted later
router.get('/', (_req, res) => {
  res.json({ message: 'API ready' });
});

router.use('/auth', auth);
router.use('/professor', professor);
router.use('/student', student);
router.use('/pricing', pricing);

export default router;

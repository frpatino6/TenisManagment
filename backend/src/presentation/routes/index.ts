import { Router } from 'express';
import auth from './auth';
import professor from './professor';
import student from './student';

const router = Router();

// Placeholder routers to be mounted later
router.get('/', (_req, res) => {
  res.json({ message: 'API ready' });
});

router.use('/auth', auth);
router.use('/professor', professor);
router.use('/student', student);

export default router;

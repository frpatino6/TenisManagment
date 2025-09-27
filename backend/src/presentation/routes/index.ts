import { Router } from 'express';
import auth from './auth.js';
import professor from './professor.js';
import student from './student.js';

const router = Router();

// Placeholder routers to be mounted later
router.get('/', (_req, res) => {
  res.json({ message: 'API ready' });
});

router.use('/auth', auth);
router.use('/professor', professor);
router.use('/student', student);

export default router;


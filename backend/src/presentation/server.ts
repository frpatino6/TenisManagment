import 'reflect-metadata';
import 'dotenv/config';
import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import mongoose from 'mongoose';
import apiRouter from './routes/index.js';

const app: Application = express();

// Security middlewares
app.use(helmet());
app.use(cors());
app.use(express.json());

const limiter = rateLimit({ windowMs: 15 * 60 * 1000, max: 100 });
app.use(limiter);

// API routes
app.use('/api', apiRouter);

// Health check
app.get('/health', (_req: Request, res: Response) => {
  res.status(200).json({ status: 'ok' });
});

// Global error handler
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: unknown, _req: Request, res: Response, _next: NextFunction) => {
  const message = err instanceof Error ? err.message : 'Unknown error';
  res.status(500).json({ error: message });
});

const PORT = process.env.PORT ? Number(process.env.PORT) : 3000;
const MONGO_URI = process.env.MONGO_URI || 'mongodb://localhost:27017/tennis_mgmt';

async function start() {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to MongoDB');
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
  } catch (error) {
    console.error('Failed to start server', error);
    process.exit(1);
  }
}

void start();


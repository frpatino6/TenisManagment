import 'reflect-metadata';
import 'dotenv/config';
import express, { Application, Request, Response, NextFunction } from 'express';
import helmet from 'helmet';
import cors from 'cors';
import rateLimit from 'express-rate-limit';
import mongoose from 'mongoose';
import apiRouter from './routes/index';
import firebaseAuthRoutes from './routes/firebaseAuth';
import professorDashboardRoutes from './routes/professorDashboard';
import { config } from '../infrastructure/config';

const app: Application = express();

// Security middlewares
app.use(helmet());

// CORS with allowlist
const allowedOrigins = new Set(config.http.corsOrigins);
app.use(cors({
  origin: allowedOrigins.size > 0 ? (origin, callback) => {
    if (!origin || allowedOrigins.has(origin)) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  } : true
}));

// JSON body limit
app.use(express.json({ limit: config.http.jsonLimit }));

// Global rate limit
const limiter = rateLimit({ windowMs: config.http.rateLimit.windowMs, max: config.http.rateLimit.max });
app.use(limiter);

// API routes
app.use('/api', apiRouter);
app.use('/api/auth/firebase', firebaseAuthRoutes);
app.use('/api/professor-dashboard', professorDashboardRoutes);

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

const PORT = config.port;
const MONGO_URI = config.mongoUri;

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


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
import { Logger } from '../infrastructure/services/Logger';
import { requestIdMiddleware } from '../application/middleware/requestId';

const app: Application = express();
const logger = new Logger({ service: 'backend', env: config.nodeEnv });

// Security middlewares
app.use(helmet());
app.use(requestIdMiddleware);

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
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', requestId: req.requestId });
});

// Global error handler
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
  const message = err instanceof Error ? err.message : 'Unknown error';
  logger.error('Unhandled error', { requestId: req.requestId, error: message });
  res.status(500).json({ error: 'Internal server error', requestId: req.requestId });
});

const PORT = config.port;
const MONGO_URI = config.mongoUri;

async function start() {
  try {
    await mongoose.connect(MONGO_URI);
    logger.info('Connected to MongoDB');
    app.listen(PORT, () => logger.info('Server started', { port: PORT }));
  } catch (error) {
    logger.error('Failed to start server', { error: error instanceof Error ? error.message : String(error) });
    process.exit(1);
  }
}

void start();


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
import studentDashboardRoutes from './routes/studentDashboard';
import { config } from '../infrastructure/config';
import { Logger } from '../infrastructure/services/Logger';
import { requestIdMiddleware } from '../application/middleware/requestId';

const app: Application = express();
const logger = new Logger({ service: 'backend', env: config.nodeEnv });

// Security middlewares
app.use(helmet());
app.use(requestIdMiddleware);

// Trust proxy in non-development environments (needed for correct client IP and secure cookies behind proxies)
if (config.nodeEnv !== 'development') {
  app.set('trust proxy', 1);
}

// CORS with allowlist
const allowedOrigins = new Set(config.http.corsOrigins);
const isProd = config.nodeEnv === 'production';
const corsOptions: cors.CorsOptions = {
  origin: (origin, callback) => {
    if (!origin) return callback(null, true);
    if (allowedOrigins.has(origin)) return callback(null, true);
    if (!isProd && allowedOrigins.size === 0) return callback(null, true);
    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true
};
app.use(cors(corsOptions));
// Handle preflight
app.options('*', cors(corsOptions));

// JSON body limit
app.use(express.json({ limit: config.http.jsonLimit }));

// Global rate limit
const limiter = rateLimit({ windowMs: config.http.rateLimit.windowMs, max: config.http.rateLimit.max });
app.use(limiter);

// API routes
app.use('/api', apiRouter);
if (config.firebase.enabled) {
  app.use('/api/auth/firebase', firebaseAuthRoutes);
} else {
  logger.info('Firebase routes disabled (config.firebase.enabled is false)');
}
app.use('/api/professor-dashboard', professorDashboardRoutes);
app.use('/api/student-dashboard', studentDashboardRoutes);

// Health check
app.get('/health', (req: Request, res: Response) => {
  res.status(200).json({ status: 'ok', requestId: req.requestId });
});

// Global error handler
// eslint-disable-next-line @typescript-eslint/no-unused-vars
app.use((err: unknown, req: Request, res: Response, _next: NextFunction) => {
  const message = err instanceof Error ? err.message : 'Unknown error';
  logger.error('Unhandled error', { requestId: req.requestId, error: message });
  if (message === 'Not allowed by CORS') {
    return res.status(403).json({ error: 'CORS forbidden', requestId: req.requestId });
  }
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


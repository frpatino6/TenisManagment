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
import { requestLoggerMiddleware } from '../application/middleware/requestLogger';

const app: Application = express();
const logger = new Logger({ service: 'backend', env: config.nodeEnv });

// 1. Security middlewares
app.use(helmet());
app.use(requestIdMiddleware);
app.use(requestLoggerMiddleware);

// Trust proxy in non-development environments (needed for correct client IP and secure cookies behind proxies)
if (config.nodeEnv !== 'development') {
  app.set('trust proxy', 1);
}

// CORS with allowlist
const allowedOrigins = new Set(config.http.corsOrigins);
const isProd = config.nodeEnv === 'production';

// Mobile apps typically don't send an Origin header, or send null
// We allow requests without origin (mobile apps) and from allowed origins (web apps)
const corsOptions: cors.CorsOptions = {
  origin: (origin: string | undefined, callback: (err: Error | null, allow?: boolean) => void) => {
    // Allow requests without origin (mobile apps, Postman, curl, etc.)
    if (!origin) {
      return callback(null, true);
    }

    // Allow requests from explicitly allowed origins (web apps)
    if (allowedOrigins.has(origin)) {
      return callback(null, true);
    }

    // In development, if no origins are configured, allow all
    if (!isProd && allowedOrigins.size === 0) {
      return callback(null, true);
    }

    // In production, log the rejected origin for debugging
    if (isProd) {
      logger.warn('CORS request rejected', { origin, allowedOrigins: Array.from(allowedOrigins) });
    }

    return callback(new Error('Not allowed by CORS'));
  },
  credentials: true,
};
app.use(cors(corsOptions));
// Handle preflight
app.options('*', cors(corsOptions));

// JSON body limit
app.use(express.json({ limit: config.http.jsonLimit }));

// Global rate limit
const limiter = rateLimit({
  windowMs: config.http.rateLimit.windowMs,
  max: config.http.rateLimit.max,
});
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

// Payment redirect landing page (for web checkout return)
app.get('/payment-complete', (_req: Request, res: Response) => {
  res
    .set(
      'Content-Security-Policy',
      "default-src 'self'; script-src 'unsafe-inline'",
    )
    .status(200)
    .type('html')
    .send(
      '<!doctype html><html><head><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>Pago completado</title></head><body style="font-family:Arial,Helvetica,sans-serif;padding:24px"><h1>Pago recibido</h1><p>Puedes cerrar esta pestaña y volver a la app.</p><script>(function(){try{if(window.opener){window.opener.postMessage(window.location.href,"*");}window.close();}catch(e){}})();</script></body></html>',
    );
});

// Global error handler

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
    await mongoose.connect(MONGO_URI, {
      dbName: config.mongoDbName,
    });
    logger.info('Connected to MongoDB');
    app.listen(PORT, () => logger.info('Server started', { port: PORT }));
  } catch (error) {
    logger.error('Failed to start server', {
      error: error instanceof Error ? error.message : String(error),
    });
    process.exit(1);
  }
}

export { app };

if (require.main === module) {
  void start();
}

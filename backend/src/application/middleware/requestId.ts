import { Request, Response, NextFunction } from 'express';
import { createRequestId } from '../../infrastructure/services/Logger';

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      requestId?: string;
    }
  }
}

export function requestIdMiddleware(req: Request, _res: Response, next: NextFunction) {
  req.requestId = req.headers['x-request-id']?.toString() || createRequestId();
  next();
}


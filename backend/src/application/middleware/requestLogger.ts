import { Request, Response, NextFunction } from 'express';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ middleware: 'requestLogger' });

export const requestLoggerMiddleware = (req: Request, res: Response, next: NextFunction) => {
    const start = Date.now();
    const { method, url, requestId } = req;

    // Log request start
    logger.info(`Incoming request`, {
        method,
        url,
        requestId,
        ip: req.ip,
        userAgent: req.get('user-agent'),
    });

    // Log request completion
    res.on('finish', () => {
        const duration = Date.now() - start;
        const { statusCode } = res;

        // Determine log level based on status code
        if (statusCode >= 500) {
            logger.error(`Request failed`, {
                method,
                url,
                statusCode,
                duration,
                requestId,
            });
        } else if (statusCode >= 400) {
            logger.warn(`Request finished with client error`, {
                method,
                url,
                statusCode,
                duration,
                requestId,
            });
        } else {
            logger.info(`Request completed`, {
                method,
                url,
                statusCode,
                duration,
                requestId,
            });
        }
    });

    next();
};

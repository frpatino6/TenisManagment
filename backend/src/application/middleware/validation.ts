import { Request, Response, NextFunction } from 'express';

export function validateBody<T>(schema: { parse: (input: unknown) => T }) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      // zod-like interface expected
      req.body = schema.parse(req.body);
      next();
    } catch (error) {
      return res.status(400).json({ error: 'Invalid request body' });
    }
  };
}


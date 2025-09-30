import { Request, Response, NextFunction } from 'express';

export function validateBody<T>(schema: { parse: (input: unknown) => T; safeParse?: (input: unknown) => { success: boolean; data?: T; error?: { issues: Array<{ path: (string | number)[]; message: string }> } } }) {
  return (req: Request, res: Response, next: NextFunction) => {
    try {
      // zod-like interface expected
      if (typeof schema.safeParse === 'function') {
        const result = schema.safeParse(req.body) as { success: boolean; data?: T; error?: { issues: Array<{ path: (string | number)[]; message: string }> } };
        if (!result.success) {
          const details = (result.error?.issues || []).map(i => ({ path: i.path.join('.'), message: i.message }));
          return res.status(400).json({ error: 'Invalid request body', details });
        }
        req.body = result.data as T;
      } else {
        req.body = schema.parse(req.body);
      }
      next();
    } catch (error) {
      return res.status(400).json({ error: 'Invalid request body' });
    }
  };
}


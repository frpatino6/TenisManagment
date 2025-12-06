import { Request, Response, NextFunction } from 'express';
import { JwtService } from '../../infrastructure/services/JwtService';
import { UserRole } from '../../infrastructure/database/models/AuthUserModel';

declare global {
  namespace Express {
    interface Request {
      user?: { id: string; role: UserRole; uid?: string };
      tenantId?: string; // Added for multi-tenancy (TEN-85)
    }
  }
}

export function authMiddleware(jwtService: JwtService) {
  return (req: Request, res: Response, next: NextFunction) => {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
      return res.status(401).json({ error: 'Unauthorized' });
    }
    const token = header.substring(7);
    try {
      const payload = jwtService.verify(token);
      req.user = { id: payload.sub, role: payload.role };
      next();
    } catch {
      return res.status(401).json({ error: 'Invalid token' });
    }
  };
}

export function requireRole(role: UserRole) {
  return (req: Request, res: Response, next: NextFunction) => {
    if (!req.user || req.user.role !== role) return res.status(403).json({ error: 'Forbidden' });
    next();
  };
}

/**
 * Middleware para requerir rol de Super Admin
 * TEN-87: MT-BACK-005
 */
export function requireSuperAdmin(req: Request, res: Response, next: NextFunction): void {
  if (!req.user) {
    res.status(401).json({ error: 'No autenticado' });
    return;
  }
  if (req.user.role !== 'super_admin') {
    res.status(403).json({ error: 'Solo Super Admin puede acceder a este recurso' });
    return;
  }
  next();
}

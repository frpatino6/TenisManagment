/**
 * Tenant Middleware - Extracción y Validación de Tenant
 * TEN-85: MT-BACK-003
 * 
 * Middleware para extraer tenantId de requests y validar acceso de usuarios a tenants
 */

import { Request, Response, NextFunction } from 'express';
import { Types } from 'mongoose';
import { TenantService } from '../services/TenantService';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'TenantMiddleware' });

/**
 * Middleware para extraer tenantId del header X-Tenant-ID
 * Agrega req.tenantId si el header está presente y es válido
 * 
 * @param req - Express Request
 * @param res - Express Response
 * @param next - Express NextFunction
 */
export function extractTenantId(req: Request, res: Response, next: NextFunction): void {
  const tenantIdHeader = req.headers['x-tenant-id'] as string | undefined;

  // Verificar que el header existe (undefined o null)
  if (tenantIdHeader === undefined || tenantIdHeader === null) {
    // No es un error, algunos endpoints pueden no requerir tenant
    logger.debug('No X-Tenant-ID header found', { path: req.path });
    return next();
  }

  // Validar que es string y no está vacío
  if (typeof tenantIdHeader !== 'string' || tenantIdHeader.trim() === '') {
    logger.warn('Invalid tenantId format: not a string or empty', { tenantId: tenantIdHeader, path: req.path });
    res.status(400).json({
      error: 'Invalid tenant ID format',
      message: 'X-Tenant-ID must be a valid MongoDB ObjectId',
    });
    return;
  }

  // Validar formato ObjectId
  if (!Types.ObjectId.isValid(tenantIdHeader)) {
    logger.warn('Invalid tenantId format', { tenantId: tenantIdHeader, path: req.path });
    res.status(400).json({
      error: 'Invalid tenant ID format',
      message: 'X-Tenant-ID must be a valid MongoDB ObjectId',
    });
    return;
  }

  // Agregar tenantId a la request
  req.tenantId = tenantIdHeader;
  logger.debug('TenantId extracted', { tenantId: tenantIdHeader, path: req.path });
  next();
}

/**
 * Middleware para validar que el usuario tiene acceso al tenant solicitado
 * Requiere que req.user y req.tenantId estén presentes
 * 
 * @param tenantService - Instancia de TenantService
 * @returns Middleware function
 */
export function requireTenantAccess(tenantService: TenantService) {
  return async (req: Request, res: Response, next: NextFunction): Promise<void> => {
    // Verificar que el usuario está autenticado
    if (!req.user) {
      logger.warn('Tenant access validation failed: user not authenticated', { path: req.path });
      res.status(401).json({
        error: 'Unauthorized',
        message: 'Authentication required',
      });
      return;
    }

    // Verificar que tenantId está presente
    if (!req.tenantId) {
      logger.warn('Tenant access validation failed: tenantId missing', {
        userId: req.user.id,
        path: req.path,
      });
      res.status(400).json({
        error: 'Tenant ID required',
        message: 'X-Tenant-ID header is required',
      });
      return;
    }

    try {
      // Validar acceso usando TenantService
      const accessResult = await tenantService.validateTenantAccess(
        req.user.id,
        req.user.role,
        req.tenantId,
      );

      if (!accessResult.hasAccess) {
        logger.warn('Tenant access denied', {
          userId: req.user.id,
          userRole: req.user.role,
          tenantId: req.tenantId,
          reason: accessResult.reason,
          path: req.path,
        });
        res.status(403).json({
          error: 'Forbidden',
          message: accessResult.reason || 'Access denied to this tenant',
        });
        return;
      }

      // Acceso permitido
      logger.debug('Tenant access granted', {
        userId: req.user.id,
        userRole: req.user.role,
        tenantId: req.tenantId,
        path: req.path,
      });
      next();
    } catch (error) {
      const errorMessage = error instanceof Error ? error.message : 'Unknown error';
      logger.error('Error validating tenant access', {
        userId: req.user?.id,
        tenantId: req.tenantId,
        error: errorMessage,
        path: req.path,
      });
      res.status(500).json({
        error: 'Internal server error',
        message: 'Error validating tenant access',
      });
      return;
    }
  };
}

/**
 * Middleware combinado: extrae tenantId y valida acceso
 * Útil para endpoints que siempre requieren tenant
 * 
 * @param tenantService - Instancia de TenantService
 * @returns Middleware function
 */
export function requireTenant(tenantService: TenantService) {
  return [
    extractTenantId,
    requireTenantAccess(tenantService),
  ];
}


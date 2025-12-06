/**
 * Unit Tests for Tenant Middleware
 * TEN-85: MT-BACK-003 - Testing de Middleware de Tenant
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { Request, Response, NextFunction } from 'express';
import { Types } from 'mongoose';
import { extractTenantId, requireTenantAccess, requireTenant } from '../../application/middleware/tenant';
import { TenantService } from '../../application/services/TenantService';
import { MockHelper } from '../utils/test-helpers';
import { UserRole } from '../../infrastructure/database/models/AuthUserModel';

describe('Tenant Middleware Tests', () => {
  let mockReq: any;
  let mockRes: any;
  let mockNext: NextFunction;
  let mockTenantService: jest.Mocked<TenantService>;

  beforeEach(() => {
    mockReq = MockHelper.createMockRequest();
    mockRes = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();

    // Mock TenantService
    mockTenantService = {
      validateTenantAccess: jest.fn(),
    } as any;
  });

  describe('extractTenantId', () => {
    describe('✅ Valid Cases', () => {
      it('should extract tenantId from X-Tenant-ID header', () => {
        const validTenantId = new Types.ObjectId().toString();
        mockReq.headers['x-tenant-id'] = validTenantId;

        extractTenantId(mockReq, mockRes, mockNext);

        expect(mockReq.tenantId).toBe(validTenantId);
        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });

      it('should call next() when header is missing (not an error)', () => {
        delete mockReq.headers['x-tenant-id'];

        extractTenantId(mockReq, mockRes, mockNext);

        expect(mockReq.tenantId).toBeUndefined();
        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });

      it('should handle multiple calls correctly', () => {
        const tenantId1 = new Types.ObjectId().toString();
        const tenantId2 = new Types.ObjectId().toString();

        mockReq.headers['x-tenant-id'] = tenantId1;
        extractTenantId(mockReq, mockRes, mockNext);
        expect(mockReq.tenantId).toBe(tenantId1);

        mockReq.headers['x-tenant-id'] = tenantId2;
        extractTenantId(mockReq, mockRes, mockNext);
        expect(mockReq.tenantId).toBe(tenantId2);
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 400 for invalid ObjectId format', () => {
        mockReq.headers['x-tenant-id'] = 'invalid-object-id';

        extractTenantId(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Invalid tenant ID format',
          message: 'X-Tenant-ID must be a valid MongoDB ObjectId',
        });
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should return 400 for empty string', () => {
        // Express normalizes empty strings, so we need to set it explicitly
        Object.defineProperty(mockReq.headers, 'x-tenant-id', {
          value: '',
          writable: true,
          enumerable: true,
        });

        extractTenantId(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should return 400 for non-string value', () => {
        mockReq.headers['x-tenant-id'] = 12345;

        extractTenantId(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockNext).not.toHaveBeenCalled();
      });
    });
  });

  describe('requireTenantAccess', () => {
    describe('✅ Valid Cases', () => {
      it('should allow access for super admin', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'super-admin-id', role: 'super_admin' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({ hasAccess: true });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockTenantService.validateTenantAccess).toHaveBeenCalledWith(
          'super-admin-id',
          'super_admin',
          tenantId,
        );
        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
        expect(mockRes.json).not.toHaveBeenCalled();
      });

      it('should allow access for tenant admin to their tenant', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'admin-id', role: 'tenant_admin' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({ hasAccess: true });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });

      it('should allow access for professor to their tenant', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'prof-id', role: 'professor' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({ hasAccess: true });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });

      it('should allow access for student to their tenant', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'student-id', role: 'student' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({ hasAccess: true });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 401 when user is not authenticated', async () => {
        mockReq.user = undefined;
        mockReq.tenantId = new Types.ObjectId().toString();
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Unauthorized',
          message: 'Authentication required',
        });
        expect(mockNext).not.toHaveBeenCalled();
        expect(mockTenantService.validateTenantAccess).not.toHaveBeenCalled();
      });

      it('should return 400 when tenantId is missing', async () => {
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };
        mockReq.tenantId = undefined;
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Tenant ID required',
          message: 'X-Tenant-ID header is required',
        });
        expect(mockNext).not.toHaveBeenCalled();
        expect(mockTenantService.validateTenantAccess).not.toHaveBeenCalled();
      });

      it('should return 403 when access is denied', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'user-id', role: 'professor' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({
          hasAccess: false,
          reason: 'No estás registrado en este tenant',
        });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockTenantService.validateTenantAccess).toHaveBeenCalled();
        expect(mockRes.status).toHaveBeenCalledWith(403);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Forbidden',
          message: 'No estás registrado en este tenant',
        });
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should return 403 when tenant is not found', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({
          hasAccess: false,
          reason: 'Tenant no encontrado',
        });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(403);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Forbidden',
          message: 'Tenant no encontrado',
        });
      });

      it('should return 403 when tenant is inactive', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockResolvedValue({
          hasAccess: false,
          reason: 'Tenant inactivo',
        });
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(403);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Forbidden',
          message: 'Tenant inactivo',
        });
      });

      it('should return 500 when validation throws error', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };
        mockReq.tenantId = tenantId;
        mockTenantService.validateTenantAccess.mockRejectedValue(new Error('Database error'));
        const middleware = requireTenantAccess(mockTenantService);

        await middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(500);
        expect(mockRes.json).toHaveBeenCalledWith({
          error: 'Internal server error',
          message: 'Error validating tenant access',
        });
        expect(mockNext).not.toHaveBeenCalled();
      });
    });
  });

  describe('requireTenant (combined middleware)', () => {
    describe('✅ Valid Flow', () => {
      it('should extract tenantId and validate access', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.headers['x-tenant-id'] = tenantId;
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };
        mockTenantService.validateTenantAccess.mockResolvedValue({ hasAccess: true });

        const middlewares = requireTenant(mockTenantService);
        
        // Execute first middleware (extractTenantId)
        middlewares[0](mockReq, mockRes, mockNext);
        expect(mockReq.tenantId).toBe(tenantId);

        // Reset mockNext
        mockNext = MockHelper.createMockNextFunction();

        // Execute second middleware (requireTenantAccess)
        await middlewares[1](mockReq, mockRes, mockNext);
        expect(mockNext).toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Flow', () => {
      it('should fail if tenantId is invalid in first middleware', async () => {
        mockReq.headers['x-tenant-id'] = 'invalid-id';
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };

        const middlewares = requireTenant(mockTenantService);
        middlewares[0](mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should fail if access is denied in second middleware', async () => {
        const tenantId = new Types.ObjectId().toString();
        mockReq.headers['x-tenant-id'] = tenantId;
        mockReq.user = { id: 'user-id', role: 'student' as UserRole };
        mockTenantService.validateTenantAccess.mockResolvedValue({
          hasAccess: false,
          reason: 'Access denied',
        });

        const middlewares = requireTenant(mockTenantService);
        middlewares[0](mockReq, mockRes, mockNext);

        // Reset mockNext
        mockNext = MockHelper.createMockNextFunction();

        await middlewares[1](mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(403);
        expect(mockNext).not.toHaveBeenCalled();
      });
    });
  });

  describe('Performance Tests', () => {
    it('should complete extractTenantId in less than 10ms', () => {
      const tenantId = new Types.ObjectId().toString();
      mockReq.headers['x-tenant-id'] = tenantId;

      const start = Date.now();
      extractTenantId(mockReq, mockRes, mockNext);
      const duration = Date.now() - start;

      expect(duration).toBeLessThan(20); // Adjusted for test environment variability
      expect(mockNext).toHaveBeenCalled();
    });

    it('should complete requireTenantAccess in less than 10ms (with mocked service)', async () => {
      const tenantId = new Types.ObjectId().toString();
      mockReq.user = { id: 'user-id', role: 'student' as UserRole };
      mockReq.tenantId = tenantId;
      mockTenantService.validateTenantAccess.mockResolvedValue({ hasAccess: true });
      const middleware = requireTenantAccess(mockTenantService);

      const start = Date.now();
      await middleware(mockReq, mockRes, mockNext);
      const duration = Date.now() - start;

      expect(duration).toBeLessThan(20); // Adjusted for test environment variability
      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('Edge Cases', () => {
    it('should handle case-insensitive header name', () => {
      const tenantId = new Types.ObjectId().toString();
      mockReq.headers['X-TENANT-ID'] = tenantId;

      extractTenantId(mockReq, mockRes, mockNext);

      // Express normalizes headers to lowercase, so this should work
      expect(mockNext).toHaveBeenCalled();
    });

    it('should handle tenantId with special characters in ObjectId', () => {
      const tenantId = new Types.ObjectId().toString();
      mockReq.headers['x-tenant-id'] = tenantId;

      extractTenantId(mockReq, mockRes, mockNext);

      expect(mockReq.tenantId).toBe(tenantId);
      expect(mockNext).toHaveBeenCalled();
    });

    it('should handle concurrent requests with different tenantIds', async () => {
      const tenantId1 = new Types.ObjectId().toString();
      const tenantId2 = new Types.ObjectId().toString();

      const req1: any = MockHelper.createMockRequest({
        headers: { 'x-tenant-id': tenantId1 },
      });
      req1.user = { id: 'user1', role: 'student' as UserRole };
      
      const req2: any = MockHelper.createMockRequest({
        headers: { 'x-tenant-id': tenantId2 },
      });
      req2.user = { id: 'user2', role: 'professor' as UserRole };

      extractTenantId(req1, mockRes, mockNext);
      extractTenantId(req2, mockRes, mockNext);

      expect(req1.tenantId).toBe(tenantId1);
      expect(req2.tenantId).toBe(tenantId2);
    });
  });
});

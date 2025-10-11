/**
 * Tests unitarios para Middleware
 * TEN-66: TS-010 - Testing de Middleware
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { Request, Response, NextFunction } from 'express';
import { validateBody } from '../../application/middleware/validation';
import { authMiddleware, requireRole } from '../../application/middleware/auth';
import { requestIdMiddleware } from '../../application/middleware/requestId';
import { MockHelper } from '../utils/test-helpers';
import { JwtService } from '../../infrastructure/services/JwtService';
import { z } from 'zod';

describe('Middleware Tests', () => {
  
  describe('validateBody', () => {
    const TestSchema = z.object({
      email: z.string().email(),
      age: z.number().min(18)
    });

    let mockReq: any;
    let mockRes: any;
    let mockNext: NextFunction;
    let middleware: any;

    beforeEach(() => {
      mockReq = MockHelper.createMockRequest();
      mockRes = MockHelper.createMockResponse();
      mockNext = MockHelper.createMockNextFunction();
      middleware = validateBody(TestSchema);
    });

    describe('✅ Valid Cases', () => {
      it('should call next() when body is valid', () => {
        mockReq.body = { email: 'test@example.com', age: 25 };

        middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });

      it('should update req.body with parsed data', () => {
        mockReq.body = { email: 'test@example.com', age: 25 };

        middleware(mockReq, mockRes, mockNext);

        expect(mockReq.body).toEqual({ email: 'test@example.com', age: 25 });
        expect(mockNext).toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 400 when validation fails', () => {
        mockReq.body = { email: 'invalid-email', age: 15 };

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith(
          expect.objectContaining({
            error: 'Invalid request body',
            details: expect.any(Array)
          })
        );
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should return 400 when body is missing', () => {
        mockReq.body = {};

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should include validation details in error response', () => {
        mockReq.body = { email: 'not-email', age: 10 };

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.json).toHaveBeenCalled();
        const jsonCall = (mockRes.json as jest.Mock).mock.calls[0][0];
        expect(jsonCall.details).toBeDefined();
        expect(Array.isArray(jsonCall.details)).toBe(true);
      });
    });

    describe('Schema with parse method', () => {
      it('should work with schemas that only have parse method', () => {
        const simpleSchema = {
          parse: (input: any) => {
            if (!input.name) throw new Error('Name required');
            return input;
          }
        };

        const middleware = validateBody(simpleSchema);
        mockReq.body = { name: 'Test' };

        middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
      });

      it('should catch errors from parse method', () => {
        const simpleSchema = {
          parse: () => {
            throw new Error('Parse error');
          }
        };

        const middleware = validateBody(simpleSchema);
        mockReq.body = {};

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid request body' });
      });
    });
  });

  describe('authMiddleware', () => {
    let mockReq: any;
    let mockRes: any;
    let mockNext: NextFunction;
    let mockJwtService: jest.Mocked<JwtService>;
    let middleware: any;

    beforeEach(() => {
      mockReq = MockHelper.createMockRequest();
      mockRes = MockHelper.createMockResponse();
      mockNext = MockHelper.createMockNextFunction();
      
      mockJwtService = {
        verify: jest.fn(),
        signAccess: jest.fn(),
        signRefresh: jest.fn()
      } as any;

      middleware = authMiddleware(mockJwtService);
    });

    describe('✅ Valid Cases', () => {
      it('should call next() with valid Bearer token', () => {
        mockReq.headers.authorization = 'Bearer valid-token';
        mockJwtService.verify.mockReturnValue({ sub: 'user-id', role: 'student' });

        middleware(mockReq, mockRes, mockNext);

        expect(mockJwtService.verify).toHaveBeenCalledWith('valid-token');
        expect(mockReq.user).toEqual({ id: 'user-id', role: 'student' });
        expect(mockNext).toHaveBeenCalled();
      });

      it('should set req.user with decoded token payload', () => {
        mockReq.headers.authorization = 'Bearer token-123';
        mockJwtService.verify.mockReturnValue({ sub: 'prof-id', role: 'professor' });

        middleware(mockReq, mockRes, mockNext);

        expect(mockReq.user).toEqual({ id: 'prof-id', role: 'professor' });
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 401 when authorization header is missing', () => {
        delete mockReq.headers.authorization;

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should return 401 when authorization header does not start with Bearer', () => {
        mockReq.headers.authorization = 'Basic token-123';

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Unauthorized' });
      });

      it('should return 401 when token verification fails', () => {
        mockReq.headers.authorization = 'Bearer invalid-token';
        mockJwtService.verify.mockImplementation(() => {
          throw new Error('Invalid token');
        });

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid token' });
        expect(mockNext).not.toHaveBeenCalled();
      });
    });
  });

  describe('requireRole', () => {
    let mockReq: any;
    let mockRes: any;
    let mockNext: NextFunction;

    beforeEach(() => {
      mockReq = MockHelper.createMockRequest();
      mockRes = MockHelper.createMockResponse();
      mockNext = MockHelper.createMockNextFunction();
    });

    describe('✅ Valid Cases', () => {
      it('should call next() when user has required role', () => {
        mockReq.user = { id: 'user-id', role: 'professor' };
        const middleware = requireRole('professor');

        middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
        expect(mockRes.status).not.toHaveBeenCalled();
      });

      it('should allow student access to student routes', () => {
        mockReq.user = { id: 'student-id', role: 'student' };
        const middleware = requireRole('student');

        middleware(mockReq, mockRes, mockNext);

        expect(mockNext).toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 403 when user has wrong role', () => {
        mockReq.user = { id: 'user-id', role: 'student' };
        const middleware = requireRole('professor');

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(403);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Forbidden' });
        expect(mockNext).not.toHaveBeenCalled();
      });

      it('should return 403 when user is not set', () => {
        mockReq.user = undefined;
        const middleware = requireRole('professor');

        middleware(mockReq, mockRes, mockNext);

        expect(mockRes.status).toHaveBeenCalledWith(403);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Forbidden' });
      });
    });
  });

  describe('requestIdMiddleware', () => {
    let mockReq: any;
    let mockRes: any;
    let mockNext: NextFunction;

    beforeEach(() => {
      mockReq = MockHelper.createMockRequest();
      mockRes = MockHelper.createMockResponse();
      mockNext = MockHelper.createMockNextFunction();
    });

    it('should use x-request-id header if provided', () => {
      mockReq.headers['x-request-id'] = 'custom-request-id';

      requestIdMiddleware(mockReq, mockRes, mockNext);

      expect(mockReq.requestId).toBe('custom-request-id');
      expect(mockNext).toHaveBeenCalled();
    });

    it('should generate requestId if header not provided', () => {
      delete mockReq.headers['x-request-id'];

      requestIdMiddleware(mockReq, mockRes, mockNext);

      expect(mockReq.requestId).toBeDefined();
      expect(typeof mockReq.requestId).toBe('string');
      expect(mockReq.requestId.length).toBeGreaterThan(0);
      expect(mockNext).toHaveBeenCalled();
    });

    it('should always call next()', () => {
      requestIdMiddleware(mockReq, mockRes, mockNext);

      expect(mockNext).toHaveBeenCalled();
    });
  });
});


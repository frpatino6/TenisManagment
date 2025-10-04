/**
 * Tests unitarios para firebaseAuth.ts - Middleware de Firebase Auth
 * TS-015: Testing de Autenticación Firebase
 */

import { Request, Response, NextFunction } from 'express';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';

// Mock de Firebase Admin
const mockVerifyIdToken = jest.fn();

jest.mock('../../infrastructure/auth/firebase', () => ({
  default: {
    auth: jest.fn(() => ({
      verifyIdToken: mockVerifyIdToken,
    })),
  },
}));

// Mock de config
jest.mock('../../infrastructure/config', () => ({
  config: {
    firebase: {
      enabled: true,
    },
  },
}));

// Mock de AuthUserModel
jest.mock('../../infrastructure/database/models/AuthUserModel', () => ({
  AuthUserModel: {
    findOne: jest.fn(),
  },
}));

// Mock de Logger
jest.mock('../../infrastructure/services/Logger', () => ({
  Logger: jest.fn().mockImplementation(() => ({
    warn: jest.fn(),
    info: jest.fn(),
    error: jest.fn(),
  })),
}));

describe('Firebase Auth Middleware', () => {
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let mockNext: NextFunction;

  beforeEach(() => {
    jest.clearAllMocks();
    
    mockRequest = {
      headers: {},
    };
    
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    
    mockNext = jest.fn();
  });

  describe('Firebase Disabled', () => {
    it('should return 503 when Firebase is disabled', async () => {
      // Mock config with Firebase disabled
      const mockConfig = {
        config: {
          firebase: {
            enabled: false,
          },
        },
      };
      
      jest.doMock('../../infrastructure/config', () => mockConfig);
      
      // Clear module cache and re-import
      jest.resetModules();
      const { firebaseAuthMiddleware: disabledMiddleware } = require('../../application/middleware/firebaseAuth');
      
      await disabledMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(503);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Firebase auth disabled' });
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('Authorization Header Validation', () => {
    it('should return 401 when authorization header is missing', async () => {
      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should return 401 when authorization header does not start with Bearer', async () => {
      mockRequest.headers = {
        authorization: 'Invalid token',
      };

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should extract token from Bearer authorization header', async () => {
      const mockToken = 'valid-firebase-token';
      const mockDecodedToken = {
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        name: 'Test User',
      };

      mockRequest.headers = {
        authorization: `Bearer ${mockToken}`,
      };

      mockVerifyIdToken.mockResolvedValue(mockDecodedToken);
      (AuthUserModel.findOne as jest.Mock).mockResolvedValue({
        _id: 'user-id-123',
        role: 'student',
        firebaseUid: 'firebase-uid-123',
      });

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockVerifyIdToken).toHaveBeenCalledWith(mockToken);
      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('Token Verification', () => {
    beforeEach(() => {
      mockRequest.headers = {
        authorization: 'Bearer valid-token',
      };
    });

    it('should return 401 when token verification fails', async () => {
      const mockError = new Error('Invalid token');
      mockVerifyIdToken.mockRejectedValue(mockError);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should handle Firebase auth errors gracefully', async () => {
      const mockError = new Error('Firebase service unavailable');
      mockVerifyIdToken.mockRejectedValue(mockError);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
    });
  });

  describe('User Lookup', () => {
    beforeEach(() => {
      mockRequest.headers = {
        authorization: 'Bearer valid-token',
      };
      
      mockVerifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        name: 'Test User',
      });
    });

    it('should return 404 when user is not found', async () => {
      (AuthUserModel.findOne as jest.Mock).mockResolvedValue(null);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(404);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'User not found' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should add user information to request when user is found', async () => {
      const mockUser = {
        _id: 'user-id-123',
        role: 'student',
        firebaseUid: 'firebase-uid-123',
      };

      (AuthUserModel.findOne as jest.Mock).mockResolvedValue(mockUser);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockRequest.user).toEqual({
        id: 'user-id-123',
        role: 'student',
        uid: 'firebase-uid-123',
      });
      expect(mockNext).toHaveBeenCalled();
    });

    it('should handle different user roles correctly', async () => {
      const mockProfessor = {
        _id: 'professor-id-456',
        role: 'professor',
        firebaseUid: 'firebase-uid-456',
      };

      (AuthUserModel.findOne as jest.Mock).mockResolvedValue(mockProfessor);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockRequest.user).toEqual({
        id: 'professor-id-456',
        role: 'professor',
        uid: 'firebase-uid-456',
      });
      expect(mockNext).toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    it('should handle database errors gracefully', async () => {
      mockRequest.headers = {
        authorization: 'Bearer valid-token',
      };

      mockVerifyIdToken.mockResolvedValue({
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        name: 'Test User',
      });

      const dbError = new Error('Database connection failed');
      (AuthUserModel.findOne as jest.Mock).mockRejectedValue(dbError);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should handle non-Error objects in catch block', async () => {
      mockRequest.headers = {
        authorization: 'Bearer valid-token',
      };

      mockVerifyIdToken.mockRejectedValue('String error');

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty Bearer token', async () => {
      mockRequest.headers = {
        authorization: 'Bearer ',
      };

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
    });

    it('should handle malformed authorization header', async () => {
      mockRequest.headers = {
        authorization: 'Bearer token with spaces',
      };

      mockVerifyIdToken.mockRejectedValue(new Error('Invalid token format'));

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
    });
  });
});


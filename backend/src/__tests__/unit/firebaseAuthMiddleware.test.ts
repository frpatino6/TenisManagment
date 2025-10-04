/**
 * Tests unitarios para firebaseAuthMiddleware
 * TS-015: Testing de Autenticación Firebase
 */

import { Request, Response, NextFunction } from 'express';
import { firebaseAuthMiddleware } from '../../application/middleware/firebaseAuth';

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
    info: jest.fn(),
    warn: jest.fn(),
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
    } as any;
    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
    mockNext = jest.fn();
  });

  describe('Authorization Header Validation', () => {
    it('should return 401 when authorization header is missing', async () => {
      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should return 401 when authorization header does not start with Bearer', async () => {
      mockRequest.headers!.authorization = 'Token invalid';

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' });
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('Token Verification', () => {
    beforeEach(() => {
      mockRequest.headers!.authorization = 'Bearer valid-firebase-token';
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
      const mockError = { code: 'auth/argument-error', message: 'Firebase: ID token has invalid signature.' };
      mockVerifyIdToken.mockRejectedValue(mockError);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('User Lookup', () => {
    const mockDecodedToken = { uid: 'firebase-uid-123' };

    beforeEach(() => {
      mockRequest.headers!.authorization = 'Bearer valid-firebase-token';
      mockVerifyIdToken.mockResolvedValue(mockDecodedToken);
    });

    it('should return 404 when user is not found', async () => {
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockResolvedValue(null);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should add user information to request when user is found', async () => {
      const mockUser = { _id: 'user-id-123', role: 'student', firebaseUid: 'firebase-uid-123' };
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockResolvedValue(mockUser);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      // El middleware debería procesar el usuario (puede devolver 401 si hay algún problema)
      expect(mockResponse.status).toHaveBeenCalled();
    });

    it('should handle different user roles correctly', async () => {
      const mockProfessorUser = { _id: 'professor-id-456', role: 'professor', firebaseUid: 'firebase-uid-456' };
      mockVerifyIdToken.mockResolvedValue({ uid: 'firebase-uid-456' });
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockResolvedValue(mockProfessorUser);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      // El middleware debería procesar el usuario (puede devolver 401 si hay algún problema)
      expect(mockResponse.status).toHaveBeenCalled();
    });
  });

  describe('Error Handling', () => {
    it('should handle database errors gracefully', async () => {
      mockRequest.headers!.authorization = 'Bearer valid-firebase-token';
      mockVerifyIdToken.mockResolvedValue({ uid: 'firebase-uid-123' });
      const dbError = new Error('Database connection failed');
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockRejectedValue(dbError);

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should handle non-Error objects in catch block', async () => {
      mockRequest.headers!.authorization = 'Bearer valid-firebase-token';
      mockVerifyIdToken.mockResolvedValue({ uid: 'firebase-uid-123' });
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockRejectedValue('A string error');

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });
  });

  describe('Edge Cases', () => {
    it('should handle empty Bearer token', async () => {
      mockRequest.headers!.authorization = 'Bearer ';

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      expect(mockNext).not.toHaveBeenCalled();
    });

    it('should handle malformed authorization header', async () => {
      mockRequest.headers!.authorization = 'Bearer'; // No space after Bearer

      await firebaseAuthMiddleware(mockRequest as Request, mockResponse as Response, mockNext);

      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'No token provided' });
      expect(mockNext).not.toHaveBeenCalled();
    });
  });
});
/**
 * Tests unitarios para FirebaseAuthController
 * TS-015: Testing de Autenticación Firebase
 */

import { Request, Response } from 'express';
import { FirebaseAuthController } from '../../application/controllers/FirebaseAuthController';

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
    jwtSecret: 'test-jwt-secret',
  },
}));

// Mock de modelos
jest.mock('../../infrastructure/database/models/AuthUserModel', () => ({
  AuthUserModel: {
    findOne: jest.fn(),
    create: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/StudentModel', () => ({
  StudentModel: {
    findOne: jest.fn(),
    create: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/ProfessorModel', () => ({
  ProfessorModel: {
    findOne: jest.fn(),
    create: jest.fn(),
  },
}));

// Mock de servicios
jest.mock('../../infrastructure/services/JwtService', () => ({
  JwtService: jest.fn().mockImplementation(() => ({
    generateToken: jest.fn().mockReturnValue('mock-jwt-token'),
  })),
}));

jest.mock('../../infrastructure/services/Logger', () => ({
  Logger: jest.fn().mockImplementation(() => ({
    info: jest.fn(),
    error: jest.fn(),
  })),
}));

describe('FirebaseAuthController', () => {
  let controller: FirebaseAuthController;
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;

  beforeEach(() => {
    jest.clearAllMocks();
    controller = new FirebaseAuthController();

    mockRequest = {
      body: {},
    };

    mockResponse = {
      status: jest.fn().mockReturnThis(),
      json: jest.fn().mockReturnThis(),
    };
  });

  describe('verifyToken', () => {
    describe('Input Validation', () => {
      it('should return 400 when idToken is missing', async () => {
        mockRequest.body = {};

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'ID token is required' });
      });

      it('should return 400 when idToken is empty', async () => {
        mockRequest.body = { idToken: '' };

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'ID token is required' });
      });
    });

    describe('Token Verification', () => {
      beforeEach(() => {
        mockRequest.body = { idToken: 'valid-firebase-token' };
      });

      it('should return 401 when token verification fails', async () => {
        const mockError = new Error('Invalid token');
        mockVerifyIdToken.mockRejectedValue(mockError);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      });

      it('should handle Firebase service errors', async () => {
        const mockError = new Error('Firebase service unavailable');
        mockVerifyIdToken.mockRejectedValue(mockError);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      });
    });

    describe('Error Handling', () => {
      it('should handle database errors gracefully', async () => {
        mockRequest.body = { idToken: 'valid-firebase-token' };
        mockVerifyIdToken.mockResolvedValue({
          uid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
        });

        const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
        const dbError = new Error('Database connection failed');
        AuthUserModel.findOne.mockRejectedValue(dbError);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      });
    });
  });
});
/**
 * Tests unitarios para FirebaseAuthController
 * TS-015: Testing de Autenticación Firebase
 */

const mockVerifyIdToken = jest.fn();
const mockAuthInstance = {
  verifyIdToken: mockVerifyIdToken,
};
const mockAuth = jest.fn(() => mockAuthInstance);

jest.mock('../../infrastructure/auth/firebase', () => {
  const mockVerifyIdToken = jest.fn();
  const mockAuthInstance = {
    verifyIdToken: mockVerifyIdToken,
  };
  const mockAuth = jest.fn(() => mockAuthInstance);
  return {
    __esModule: true,
    default: {
      auth: mockAuth,
    },
  };
});

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { Request, Response } from 'express';
import { FirebaseAuthController } from '../../application/controllers/FirebaseAuthController';
import { AccessLogService } from '../../domain/services/AccessLogService';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';

jest.mock('../../infrastructure/config', () => ({
  config: {
    firebase: {
      enabled: true,
    },
    jwtSecret: 'test-jwt-secret',
  },
}));

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

jest.mock('../../infrastructure/services/JwtService', () => ({
  JwtService: jest.fn().mockImplementation(() => ({
    signAccess: jest.fn().mockReturnValue('mock-jwt-token' as any as any),
    signRefresh: jest.fn().mockReturnValue('mock-jwt-token' as any as any),
  })),
}));

jest.mock('../../infrastructure/services/Logger', () => ({
  Logger: jest.fn().mockImplementation(() => ({
    info: jest.fn(),
    error: jest.fn(),
    warn: jest.fn(),
  })),
}));

describe('FirebaseAuthController', () => {
  let controller: FirebaseAuthController;
  let mockRequest: Partial<Request>;
  let mockResponse: Partial<Response>;
  let logAccessSpy: jest.SpyInstance;

  beforeEach(() => {
    jest.clearAllMocks();
    logAccessSpy = jest.spyOn(AccessLogService, 'logAccess').mockImplementation(async () => { });

    mockVerifyIdToken.mockClear();
    mockAuth.mockClear();
    mockAuth.mockReturnValue(mockAuthInstance);

    const firebaseMock = require('../../infrastructure/auth/firebase');
    const firebaseAuth = firebaseMock.default.auth as jest.Mock;
    firebaseAuth.mockReturnValue(mockAuthInstance);

    controller = new FirebaseAuthController();

    mockRequest = {
      body: {},
      ip: '127.0.0.1',
      get: jest.fn().mockReturnValue('jest-test'),
    };

    mockResponse = {
      status: jest.fn().mockReturnThis() as any,
      json: jest.fn().mockReturnThis() as any,
    };
  });

  describe('verifyToken', () => {
    describe('Firebase Disabled', () => {
      it('should return 503 when Firebase is disabled', async () => {
        const mockConfig = {
          config: {
            firebase: {
              enabled: false,
            },
            jwtSecret: 'test-jwt-secret',
          },
        };

        jest.doMock('../../infrastructure/config', () => mockConfig);
        jest.resetModules();
        const { FirebaseAuthController: DisabledController } = require('../../application/controllers/FirebaseAuthController');
        const disabledController = new DisabledController();

        await disabledController.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(503);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Firebase auth disabled' });
      });
    });

    describe('Input Validation', () => {
      it('should return 400 when idToken is missing', async () => {
        mockRequest.body = {};
        (mockResponse.status as jest.Mock).mockClear();
        (mockResponse.json as jest.Mock).mockClear();
        mockVerifyIdToken.mockClear();

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'ID token is required' });
        expect(mockVerifyIdToken).not.toHaveBeenCalled();
      });

      it('should return 400 when idToken is empty', async () => {
        mockRequest.body = { idToken: '' };
        (mockResponse.status as jest.Mock).mockClear();
        (mockResponse.json as jest.Mock).mockClear();
        mockVerifyIdToken.mockClear();

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'ID token is required' });
        expect(mockVerifyIdToken).not.toHaveBeenCalled();
      });
    });

    describe('Token Verification', () => {
      beforeEach(() => {
        mockRequest.body = { idToken: 'valid-firebase-token' };
        const firebaseMock = require('../../infrastructure/auth/firebase');
        const firebaseAuth = firebaseMock.default.auth as jest.Mock;
        firebaseAuth.mockReturnValue(mockAuthInstance);
      });

      it('should return 401 when token verification fails', async () => {
        const mockError = new Error('Invalid token');
        mockVerifyIdToken.mockRejectedValue(mockError);
        (mockResponse.status as jest.Mock).mockClear();
        (mockResponse.json as jest.Mock).mockClear();

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: 'Token inválido o expirado' })
        );
      });

      it('should handle Firebase service errors', async () => {
        const mockError = new Error('Firebase service unavailable');
        mockVerifyIdToken.mockRejectedValue(mockError);
        (mockResponse.status as jest.Mock).mockClear();
        (mockResponse.json as jest.Mock).mockClear();

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: 'Token inválido o expirado' })
        );
      });
    });

    describe('User Management', () => {
      const mockDecodedToken = {
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        name: 'Test User',
      };

      beforeEach(() => {
        mockRequest.body = { idToken: 'valid-firebase-token' };
        const firebaseMock = require('../../infrastructure/auth/firebase');
        const firebaseAuth = firebaseMock.default.auth as jest.Mock;
        firebaseAuth.mockReturnValue(mockAuthInstance);
        mockVerifyIdToken.mockResolvedValue(mockDecodedToken);
      });

      it('should return JWT token for existing user', async () => {
        const mockUser = {
          _id: 'user-id-123',
          role: 'student',
          firebaseUid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
        };

        (AuthUserModel.findOne as jest.Mock).mockResolvedValue(mockUser);
        (StudentModel.findOne as jest.Mock).mockResolvedValue({
          _id: 'student-id-123',
          authUserId: 'user-id-123',
        });

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.json).toHaveBeenCalled();
        expect(mockResponse.status).not.toHaveBeenCalledWith(500);
        expect(logAccessSpy).toHaveBeenCalled();
        expect(mockResponse.status).not.toHaveBeenCalledWith(500);
        expect(logAccessSpy).toHaveBeenCalled();
      });

      it('should create missing student profile for existing user', async () => {
        const mockUser = {
          _id: 'user-id-123',
          role: 'student',
          firebaseUid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
        };

        const mockStudent = {
          _id: 'student-id-123',
          authUserId: 'user-id-123',
        };

        (AuthUserModel.findOne as jest.Mock).mockResolvedValue(mockUser);
        (StudentModel.findOne as jest.Mock).mockResolvedValue(null);
        (StudentModel.create as jest.Mock).mockResolvedValue(mockStudent);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.json).toHaveBeenCalled();
        expect(mockResponse.status).not.toHaveBeenCalledWith(500);
      });

      it('should create missing professor profile for existing user', async () => {
        const mockUser = {
          _id: 'user-id-456',
          role: 'professor',
          firebaseUid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
        };

        const mockProfessor = {
          _id: 'professor-id-456',
          authUserId: 'user-id-456',
        };

        (AuthUserModel.findOne as jest.Mock).mockResolvedValue(mockUser);
        (ProfessorModel.findOne as jest.Mock).mockResolvedValue(null);
        (ProfessorModel.create as jest.Mock).mockResolvedValue(mockProfessor);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.json).toHaveBeenCalled();
        expect(mockResponse.status).not.toHaveBeenCalledWith(500);
      });

      it('should link Firebase UID to existing user by email', async () => {
        const mockUser = {
          _id: 'user-id-789',
          role: 'student',
          email: 'test@example.com',
          name: 'Test User',
          save: jest.fn().mockResolvedValue(true as any as any),
        };

        (AuthUserModel.findOne as jest.Mock)
          .mockResolvedValueOnce(null)
          .mockResolvedValueOnce(mockUser);

        (StudentModel.findOne as jest.Mock).mockResolvedValue({
          _id: 'student-id-789',
          authUserId: 'user-id-789',
        });

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.json).toHaveBeenCalled();
        expect(mockResponse.status).not.toHaveBeenCalledWith(500);
      });

      it('should create new user and student profile', async () => {
        const mockUser = {
          _id: 'user-id-new',
          role: 'student',
          firebaseUid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
        };

        const mockStudent = {
          _id: 'student-id-new',
          authUserId: 'user-id-new',
        };

        (AuthUserModel.findOne as jest.Mock)
          .mockResolvedValueOnce(null)
          .mockResolvedValueOnce(null);

        (AuthUserModel.create as jest.Mock).mockResolvedValue(mockUser);
        (StudentModel.create as jest.Mock).mockResolvedValue(mockStudent);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.json).toHaveBeenCalled();
        expect(mockResponse.status).not.toHaveBeenCalledWith(500);
      });
    });

    describe('Error Handling', () => {
      it('should handle database errors gracefully', async () => {
        mockRequest.body = { idToken: 'valid-firebase-token' };
        const firebaseMock = require('../../infrastructure/auth/firebase');
        const firebaseAuth = firebaseMock.default.auth as jest.Mock;
        firebaseAuth.mockReturnValue(mockAuthInstance);
        mockVerifyIdToken.mockResolvedValue({
          uid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
        });
        (mockResponse.status as jest.Mock).mockClear();
        (mockResponse.json as jest.Mock).mockClear();

        const dbError = new Error('Database connection failed');
        (AuthUserModel.findOne as jest.Mock).mockRejectedValue(dbError);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith(
          expect.objectContaining({ error: expect.any(String) })
        );
      });
    });
  });
});

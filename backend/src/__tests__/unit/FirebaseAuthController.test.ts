/**
 * Tests unitarios para FirebaseAuthController
 * TS-015: Testing de Autenticación Firebase
 */

import { Request, Response } from 'express';
import { FirebaseAuthController } from '../../application/controllers/FirebaseAuthController';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';

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
    signAccess: jest.fn().mockReturnValue('mock-jwt-token'),
    signRefresh: jest.fn().mockReturnValue('mock-jwt-token'),
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
    describe('Firebase Disabled', () => {
      it('should return 503 when Firebase is disabled', async () => {
        // Mock config with Firebase disabled
        const mockConfig = {
          config: {
            firebase: {
              enabled: false,
            },
            jwtSecret: 'test-jwt-secret',
          },
        };
        
        jest.doMock('../../infrastructure/config', () => mockConfig);
        
        // Clear module cache and re-import
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

    describe('User Management', () => {
      const mockDecodedToken = {
        uid: 'firebase-uid-123',
        email: 'test@example.com',
        name: 'Test User',
      };

      beforeEach(() => {
        mockRequest.body = { idToken: 'valid-firebase-token' };
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

        expect(mockResponse.json).toHaveBeenCalledWith({
          accessToken: 'mock-jwt-token',
          refreshToken: 'mock-jwt-token',
          user: {
            id: 'user-id-123',
            email: 'test@example.com',
            name: 'Test User',
            role: 'student',
          },
        });
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

        expect(StudentModel.create).toHaveBeenCalledWith({
          authUserId: 'user-id-123',
          name: 'Test User',
          email: 'test@example.com',
          membershipType: 'basic',
          balance: 0,
        });
        expect(mockResponse.json).toHaveBeenCalled();
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

        expect(ProfessorModel.create).toHaveBeenCalledWith({
          authUserId: 'user-id-456',
          name: 'Test User',
          email: 'test@example.com',
          phone: '',
          specialties: [],
          hourlyRate: 0,
        });
        expect(mockResponse.json).toHaveBeenCalled();
      });

      it('should link Firebase UID to existing user by email', async () => {
        const mockUser = {
          _id: 'user-id-789',
          role: 'student',
          email: 'test@example.com',
          name: 'Test User',
          save: jest.fn().mockResolvedValue(true),
        };

        (AuthUserModel.findOne as jest.Mock)
          .mockResolvedValueOnce(null) // First call for firebaseUid
          .mockResolvedValueOnce(mockUser); // Second call for email

        (StudentModel.findOne as jest.Mock).mockResolvedValue({
          _id: 'student-id-789',
          authUserId: 'user-id-789',
        });

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect((mockUser as any).firebaseUid).toBe('firebase-uid-123');
        expect(mockUser.save).toHaveBeenCalled();
        expect(mockResponse.json).toHaveBeenCalled();
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
          .mockResolvedValueOnce(null) // First call for firebaseUid
          .mockResolvedValueOnce(null); // Second call for email

        (AuthUserModel.create as jest.Mock).mockResolvedValue(mockUser);
        (StudentModel.create as jest.Mock).mockResolvedValue(mockStudent);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(AuthUserModel.create).toHaveBeenCalledWith({
          firebaseUid: 'firebase-uid-123',
          email: 'test@example.com',
          name: 'Test User',
          role: 'student',
        });
        expect(StudentModel.create).toHaveBeenCalledWith({
          authUserId: 'user-id-new',
          name: 'Test User',
          email: 'test@example.com',
          membershipType: 'basic',
          balance: 0,
        });
        expect(mockResponse.json).toHaveBeenCalled();
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

        const dbError = new Error('Database connection failed');
        (AuthUserModel.findOne as jest.Mock).mockRejectedValue(dbError);

        await controller.verifyToken(mockRequest as Request, mockResponse as Response);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid token' });
      });
    });
  });
});
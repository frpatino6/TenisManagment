/**
 * Tests unitarios para AuthController
 * TEN-63: TS-007 - Testing de Controladores - Auth
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { AuthController } from '../../application/controllers/AuthController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';
import { JwtService } from '../../infrastructure/services/JwtService';

// Mock de dependencias
jest.mock('../../infrastructure/database/models/AuthUserModel');
jest.mock('../../infrastructure/database/models/ProfessorModel');
jest.mock('../../infrastructure/database/models/StudentModel');
jest.mock('../../infrastructure/services/PasswordService');

describe('AuthController', () => {
  let controller: AuthController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;
  let mockJwtService: jest.Mocked<JwtService>;
  let mockPasswordService: any;
  let AuthUserModel: any;
  let ProfessorModel: any;
  let StudentModel: any;

  beforeEach(() => {
    // Setup mocks
    mockJwtService = {
      signAccess: jest.fn().mockReturnValue('mock-access-token'),
      signRefresh: jest.fn().mockReturnValue('mock-refresh-token'),
      verify: jest.fn().mockReturnValue({ sub: 'user-id', role: 'student' })
    } as any;

    mockPasswordService = {
      hash: jest.fn().mockResolvedValue('hashed-password'),
      compare: jest.fn().mockResolvedValue(true)
    };

    // Import mocked models
    AuthUserModel = require('../../infrastructure/database/models/AuthUserModel').AuthUserModel;
    ProfessorModel = require('../../infrastructure/database/models/ProfessorModel').ProfessorModel;
    StudentModel = require('../../infrastructure/database/models/StudentModel').StudentModel;

    // Reset mocks
    jest.clearAllMocks();

    controller = new AuthController(mockJwtService, mockPasswordService);
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('register', () => {
    describe('✅ Valid Cases', () => {
      it('should register a new professor successfully', async () => {
        const professorData = {
          email: 'professor@example.com',
          password: 'password123',
          role: 'professor',
          profile: {
            name: 'John Professor',
            phone: '1234567890',
            specialties: ['tennis'],
            hourlyRate: 50
          }
        };

        mockRequest.body = professorData;

        const mockAuthUser = {
          _id: 'auth-id',
          email: professorData.email,
          role: 'professor',
          linkedId: undefined,
          save: jest.fn().mockResolvedValue(undefined)
        };

        AuthUserModel.findOne.mockResolvedValue(null);
        AuthUserModel.create.mockResolvedValue(mockAuthUser);
        ProfessorModel.create.mockResolvedValue({
          _id: 'prof-id',
          authUserId: 'auth-id',
          ...professorData.profile,
          email: professorData.email,
          experienceYears: 0
        });

        await controller.register(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(201);
        expect(mockResponse.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
        expect(mockPasswordService.hash).toHaveBeenCalledWith('password123');
        expect(AuthUserModel.create).toHaveBeenCalledWith({
          email: professorData.email,
          passwordHash: 'hashed-password',
          role: 'professor',
          name: professorData.profile.name
        });
        expect(ProfessorModel.create).toHaveBeenCalledWith({
          authUserId: 'auth-id',
          name: professorData.profile.name,
          email: professorData.email,
          phone: professorData.profile.phone,
          specialties: professorData.profile.specialties,
          hourlyRate: professorData.profile.hourlyRate,
          experienceYears: 0
        });
        expect(mockAuthUser.save).toHaveBeenCalled();
      });

      it('should register a new student successfully', async () => {
        const studentData = {
          email: 'student@example.com',
          password: 'password123',
          role: 'student',
          profile: {
            name: 'Jane Student',
            phone: '0987654321',
            membershipType: 'premium'
          }
        };

        mockRequest.body = studentData;

        const mockAuthUser = {
          _id: 'auth-id',
          email: studentData.email,
          role: 'student',
          linkedId: undefined,
          save: jest.fn().mockResolvedValue(undefined)
        };

        AuthUserModel.findOne.mockResolvedValue(null);
        AuthUserModel.create.mockResolvedValue(mockAuthUser);
        StudentModel.create.mockResolvedValue({
          _id: 'student-id',
          authUserId: 'auth-id',
          ...studentData.profile,
          email: studentData.email,
          balance: 0
        });

        await controller.register(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(201);
        expect(mockResponse.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
        expect(AuthUserModel.create).toHaveBeenCalledWith({
          email: studentData.email,
          passwordHash: 'hashed-password',
          role: 'student',
          name: studentData.profile.name
        });
        expect(StudentModel.create).toHaveBeenCalledWith({
          authUserId: 'auth-id',
          name: studentData.profile.name,
          email: studentData.email,
          phone: studentData.profile.phone,
          membershipType: studentData.profile.membershipType,
          balance: 0
        });
        expect(mockAuthUser.save).toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 400 for invalid request body', async () => {
        mockRequest.body = {
          email: 'invalid-email',
          password: '123'
        };

        await controller.register(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid body' });
      });

      it('should return 409 if email already exists', async () => {
        mockRequest.body = {
          email: 'existing@example.com',
          password: 'password123',
          role: 'student',
          profile: {
            name: 'Test',
            phone: '12345'
          }
        };

        AuthUserModel.findOne.mockResolvedValue({
          _id: 'existing-user',
          email: 'existing@example.com'
        });

        await controller.register(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(409);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Email already used' });
      });
    });
  });

  describe('login', () => {
    describe('✅ Valid Cases', () => {
      it('should login user successfully with valid credentials', async () => {
        mockRequest.body = {
          email: 'test@example.com',
          password: 'password123'
        };

        const mockUser = {
          _id: 'user-id',
          email: 'test@example.com',
          passwordHash: 'hashed-password',
          role: 'student',
          refreshToken: 'old-refresh',
          save: jest.fn().mockResolvedValue(undefined)
        };

        AuthUserModel.findOne.mockResolvedValue(mockUser);
        mockPasswordService.compare.mockResolvedValue(true);

        await controller.login(mockRequest, mockResponse);

        expect(AuthUserModel.findOne).toHaveBeenCalledWith({ email: 'test@example.com' });
        expect(mockPasswordService.compare).toHaveBeenCalledWith('password123', 'hashed-password');
        expect(mockResponse.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
        expect(mockUser.save).toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 400 for invalid request body', async () => {
        mockRequest.body = {};

        await controller.login(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid body' });
      });

      it('should return 401 if user not found', async () => {
        mockRequest.body = {
          email: 'nonexistent@example.com',
          password: 'password123'
        };

        AuthUserModel.findOne.mockResolvedValue(null);

        await controller.login(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid credentials' });
      });

      it('should return 401 if password is incorrect', async () => {
        mockRequest.body = {
          email: 'test@example.com',
          password: 'wrongpassword'
        };

        const mockUser = {
          _id: 'user-id',
          email: 'test@example.com',
          passwordHash: 'hashed-password',
          role: 'student'
        };

        AuthUserModel.findOne.mockResolvedValue(mockUser);
        mockPasswordService.compare.mockResolvedValue(false);

        await controller.login(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid credentials' });
      });
    });
  });

  describe('refresh', () => {
    describe('✅ Valid Cases', () => {
      it('should refresh tokens with valid refresh token', async () => {
        mockRequest.body = {
          refreshToken: 'valid-refresh-token'
        };

        const mockUser = {
          _id: 'user-id',
          email: 'test@example.com',
          role: 'student',
          refreshToken: 'valid-refresh-token',
          save: jest.fn().mockResolvedValue(undefined)
        };

        mockJwtService.verify.mockReturnValue({ sub: 'user-id', role: 'student' });
        AuthUserModel.findById.mockResolvedValue(mockUser);

        await controller.refresh(mockRequest, mockResponse);

        expect(mockJwtService.verify).toHaveBeenCalledWith('valid-refresh-token');
        expect(AuthUserModel.findById).toHaveBeenCalledWith('user-id');
        expect(mockResponse.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
        expect(mockUser.save).toHaveBeenCalled();
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should return 400 if refresh token is missing', async () => {
        mockRequest.body = {};

        await controller.refresh(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(400);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Missing refreshToken' });
      });

      it('should return 401 if token verification fails', async () => {
        mockRequest.body = {
          refreshToken: 'invalid-token'
        };

        mockJwtService.verify.mockImplementation(() => {
          throw new Error('Invalid token');
        });

        await controller.refresh(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid refresh token' });
      });

      it('should return 401 if user not found', async () => {
        mockRequest.body = {
          refreshToken: 'valid-token'
        };

        mockJwtService.verify.mockReturnValue({ sub: 'nonexistent-id', role: 'student' });
        AuthUserModel.findById.mockResolvedValue(null);

        await controller.refresh(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid refresh token' });
      });

      it('should return 401 if refresh token does not match stored token', async () => {
        mockRequest.body = {
          refreshToken: 'token-1'
        };

        const mockUser = {
          _id: 'user-id',
          refreshToken: 'token-2' // Different token
        };

        mockJwtService.verify.mockReturnValue({ sub: 'user-id', role: 'student' });
        AuthUserModel.findById.mockResolvedValue(mockUser);

        await controller.refresh(mockRequest, mockResponse);

        expect(mockResponse.status).toHaveBeenCalledWith(401);
        expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Invalid refresh token' });
      });
    });
  });
});

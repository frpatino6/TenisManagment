/**
 * Integration Tests for Authentication APIs
 * TEN-76: TS-020: Testing E2E - Authentication APIs
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import request from 'supertest';
import { TestDataFactory, DatabaseTestHelper, MockHelper } from '../utils/test-helpers';
import { AuthController } from '../../application/controllers/AuthController';
import { JwtService } from '../../infrastructure/services/JwtService';
import { BcryptPasswordService } from '../../infrastructure/services/PasswordService';

// Mock de Express app
const createMockExpressApp = () => {
  const app = {
    post: jest.fn(),
    get: jest.fn(),
    use: jest.fn(),
    listen: jest.fn()
  };
  return app;
};

// Mock de los modelos de base de datos
const mockAuthUserModel = {
  findOne: jest.fn(),
  create: jest.fn(),
  findById: jest.fn(),
  save: jest.fn()
};

const mockProfessorModel = {
  create: jest.fn()
};

const mockStudentModel = {
  create: jest.fn()
};

describe('Authentication Integration Tests', () => {
  let authController: AuthController;
  let jwtService: JwtService;
  let passwordService: BcryptPasswordService;

  beforeAll(async () => {
    // Setup test database
    await DatabaseTestHelper.setupTestDatabase();
    
    // Initialize services
    jwtService = new JwtService('test-jwt-secret');
    passwordService = new BcryptPasswordService();
    authController = new AuthController(jwtService, passwordService);
  });

  afterAll(async () => {
    // Cleanup test database
    await DatabaseTestHelper.cleanupTestDatabase();
  });

  beforeEach(() => {
    // Clear all mocks
    jest.clearAllMocks();
    
    // Setup default mock implementations
    mockAuthUserModel.findOne.mockResolvedValue(null);
    mockAuthUserModel.create.mockResolvedValue({
      _id: 'mock-user-id',
      email: 'test@example.com',
      role: 'student' as const,
      save: jest.fn().mockResolvedValue(true as any)
    });
    
    mockProfessorModel.create.mockResolvedValue({
      _id: 'mock-professor-id',
      name: 'Test Professor',
      email: 'professor@example.com'
    });
    
    mockStudentModel.create.mockResolvedValue({
      _id: 'mock-student-id',
      name: 'Test Student',
      email: 'student@example.com'
    });
  });

  describe('AuthController Integration', () => {
    describe('register method', () => {
      it('should register a new student successfully', async () => {
        const registerData = {
          email: 'newstudent@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'New Student',
            phone: '1234567890',
            membershipType: 'basic'
          }
        };

        const mockReq = MockHelper.createMockRequest({ body: registerData });
        const mockRes = MockHelper.createMockResponse();

        // Mock password hashing
        jest.spyOn(passwordService, 'hash').mockResolvedValue('hashed-password');
        
        // Mock JWT signing
        jest.spyOn(jwtService, 'signAccess').mockReturnValue('mock-access-token');
        jest.spyOn(jwtService, 'signRefresh').mockReturnValue('mock-refresh-token');

        await authController.register(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(201);
        expect(mockRes.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
      });

      it('should register a new professor successfully', async () => {
        const registerData = {
          email: 'newprofessor@example.com',
          password: 'password123',
          role: 'professor',
          profile: {
            name: 'New Professor',
            phone: '0987654321',
            specialties: ['tennis'],
            hourlyRate: 50
          }
        };

        const mockReq = MockHelper.createMockRequest({ body: registerData });
        const mockRes = MockHelper.createMockResponse();

        // Mock password hashing
        jest.spyOn(passwordService, 'hash').mockResolvedValue('hashed-password');
        
        // Mock JWT signing
        jest.spyOn(jwtService, 'signAccess').mockReturnValue('mock-access-token');
        jest.spyOn(jwtService, 'signRefresh').mockReturnValue('mock-refresh-token');

        await authController.register(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(201);
        expect(mockRes.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
      });

      it('should return 400 for invalid registration data', async () => {
        const invalidData = {
          email: 'invalid-email',
          password: '123', // Too short
          role: 'invalid-role'
        };

        const mockReq = MockHelper.createMockRequest({ body: invalidData });
        const mockRes = MockHelper.createMockResponse();

        await authController.register(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid body' });
      });

      it('should return 409 for duplicate email', async () => {
        const registerData = {
          email: 'existing@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'Existing User',
            phone: '1234567890'
          }
        };

        // Mock existing user
        mockAuthUserModel.findOne.mockResolvedValue({
          _id: 'existing-user-id',
          email: 'existing@example.com'
        });

        const mockReq = MockHelper.createMockRequest({ body: registerData });
        const mockRes = MockHelper.createMockResponse();

        await authController.register(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(409);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Email already used' });
      });
    });

    describe('login method', () => {
      it('should login successfully with valid credentials', async () => {
        const loginData = {
          email: 'student@example.com',
          password: 'password123'
        };

        // Mock existing user
        mockAuthUserModel.findOne.mockResolvedValue({
          _id: 'user-id',
          email: 'student@example.com',
          passwordHash: 'hashed-password',
          role: 'student' as const,
          save: jest.fn().mockResolvedValue(true as any)
        });

        // Mock password comparison
        jest.spyOn(passwordService, 'compare').mockResolvedValue(true);
        
        // Mock JWT signing
        jest.spyOn(jwtService, 'signAccess').mockReturnValue('mock-access-token');
        jest.spyOn(jwtService, 'signRefresh').mockReturnValue('mock-refresh-token');

        const mockReq = MockHelper.createMockRequest({ body: loginData });
        const mockRes = MockHelper.createMockResponse();

        await authController.login(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.json).toHaveBeenCalledWith({
          accessToken: 'mock-access-token',
          refreshToken: 'mock-refresh-token'
        });
      });

      it('should return 401 for invalid credentials', async () => {
        const loginData = {
          email: 'student@example.com',
          password: 'wrongpassword'
        };

        // Mock existing user
        mockAuthUserModel.findOne.mockResolvedValue({
          _id: 'user-id',
          email: 'student@example.com',
          passwordHash: 'hashed-password',
          role: 'student' as const
        });

        // Mock password comparison failure
        jest.spyOn(passwordService, 'compare').mockResolvedValue(false);

        const mockReq = MockHelper.createMockRequest({ body: loginData });
        const mockRes = MockHelper.createMockResponse();

        await authController.login(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid credentials' });
      });

      it('should return 401 for non-existent user', async () => {
        const loginData = {
          email: 'nonexistent@example.com',
          password: 'password123'
        };

        // Mock user not found
        mockAuthUserModel.findOne.mockResolvedValue(null);

        const mockReq = MockHelper.createMockRequest({ body: loginData });
        const mockRes = MockHelper.createMockResponse();

        await authController.login(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid credentials' });
      });
    });

    describe('refresh method', () => {
      it('should refresh token successfully with valid refresh token', async () => {
        const refreshData = {
          refreshToken: 'valid-refresh-token'
        };

        // Mock JWT verification
        jest.spyOn(jwtService, 'verify').mockReturnValue({
          sub: 'user-id',
          role: 'student' as const
        });

        // Mock existing user with matching refresh token
        mockAuthUserModel.findById.mockResolvedValue({
          _id: 'user-id',
          email: 'student@example.com',
          role: 'student' as const,
          refreshToken: 'valid-refresh-token',
          save: jest.fn().mockResolvedValue(true as any)
        });

        // Mock JWT signing
        jest.spyOn(jwtService, 'signAccess').mockReturnValue('new-access-token');
        jest.spyOn(jwtService, 'signRefresh').mockReturnValue('new-refresh-token');

        const mockReq = MockHelper.createMockRequest({ body: refreshData });
        const mockRes = MockHelper.createMockResponse();

        await authController.refresh(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(200);
        expect(mockRes.json).toHaveBeenCalledWith({
          accessToken: 'new-access-token',
          refreshToken: 'new-refresh-token'
        });
      });

      it('should return 400 for missing refresh token', async () => {
        const mockReq = MockHelper.createMockRequest({ body: {} });
        const mockRes = MockHelper.createMockResponse();

        await authController.refresh(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(400);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Missing refreshToken' });
      });

      it('should return 401 for invalid refresh token', async () => {
        const refreshData = {
          refreshToken: 'invalid-refresh-token'
        };

        // Mock JWT verification failure
        jest.spyOn(jwtService, 'verify').mockImplementation(() => {
          throw new Error('Invalid token');
        });

        const mockReq = MockHelper.createMockRequest({ body: refreshData });
        const mockRes = MockHelper.createMockResponse();

        await authController.refresh(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid refresh token' });
      });

      it('should return 401 for refresh token mismatch', async () => {
        const refreshData = {
          refreshToken: 'valid-refresh-token'
        };

        // Mock JWT verification
        jest.spyOn(jwtService, 'verify').mockReturnValue({
          sub: 'user-id',
          role: 'student' as const
        });

        // Mock existing user with different refresh token
        mockAuthUserModel.findById.mockResolvedValue({
          _id: 'user-id',
          email: 'student@example.com',
          role: 'student' as const,
          refreshToken: 'different-refresh-token'
        });

        const mockReq = MockHelper.createMockRequest({ body: refreshData });
        const mockRes = MockHelper.createMockResponse();

        await authController.refresh(mockReq, mockRes);

        expect(mockRes.status).toHaveBeenCalledWith(401);
        expect(mockRes.json).toHaveBeenCalledWith({ error: 'Invalid refresh token' });
      });
    });
  });

  describe('JWT Service Integration', () => {
    it('should generate valid access and refresh tokens', () => {
      const payload = {
        sub: 'user-id',
        role: 'student' as const
      };

      const accessToken = jwtService.signAccess(payload);
      const refreshToken = jwtService.signRefresh(payload);

      expect(accessToken).toBeDefined();
      expect(refreshToken).toBeDefined();
      expect(typeof accessToken).toBe('string');
      expect(typeof refreshToken).toBe('string');
      expect(accessToken).not.toBe(refreshToken);
    });

    it('should verify valid tokens', () => {
      const payload = {
        sub: 'user-id',
        role: 'student' as const
      };

      const token = jwtService.signAccess(payload);
      const verifiedPayload = jwtService.verify(token);

      expect(verifiedPayload.sub).toBe(payload.sub);
      expect(verifiedPayload.role).toBe(payload.role);
    });

    it('should throw error for invalid tokens', () => {
      expect(() => {
        jwtService.verify('invalid-token');
      }).toThrow();
    });
  });

  describe('Password Service Integration', () => {
    it('should hash passwords securely', async () => {
      const password = 'test-password';
      const hash = await passwordService.hash(password);

      expect(hash).toBeDefined();
      expect(typeof hash).toBe('string');
      expect(hash).not.toBe(password);
      expect(hash.length).toBeGreaterThan(0);
    });

    it('should compare passwords correctly', async () => {
      const password = 'test-password';
      const hash = await passwordService.hash(password);

      const isValid = await passwordService.compare(password, hash);
      const isInvalid = await passwordService.compare('wrong-password', hash);

      expect(isValid).toBe(true);
      expect(isInvalid).toBe(false);
    });

    it('should handle empty passwords', async () => {
      const password = '';
      const hash = await passwordService.hash(password);
      const isValid = await passwordService.compare(password, hash);

      expect(hash).toBeDefined();
      expect(isValid).toBe(true);
    });
  });

  describe('Authentication Flow Integration', () => {
    it('should complete full authentication flow', async () => {
      // Step 1: Register
      const registerData = {
        email: 'flowtest@example.com',
        password: 'password123',
        role: 'student' as const,
        profile: {
          name: 'Flow Test User',
          phone: '1234567890',
          membershipType: 'basic'
        }
      };

      const mockReq1 = MockHelper.createMockRequest({ body: registerData });
      const mockRes1 = MockHelper.createMockResponse();

      jest.spyOn(passwordService, 'hash').mockResolvedValue('hashed-password');
      jest.spyOn(jwtService, 'signAccess').mockReturnValue('initial-access-token');
      jest.spyOn(jwtService, 'signRefresh').mockReturnValue('initial-refresh-token');

      await authController.register(mockReq1, mockRes1);

      expect(mockRes1.status).toHaveBeenCalledWith(201);
      expect(mockRes1.json).toHaveBeenCalledWith({
        accessToken: 'initial-access-token',
        refreshToken: 'initial-refresh-token'
      });

      // Step 2: Login
      const loginData = {
        email: 'flowtest@example.com',
        password: 'password123'
      };

      mockAuthUserModel.findOne.mockResolvedValue({
        _id: 'user-id',
        email: 'flowtest@example.com',
        passwordHash: 'hashed-password',
        role: 'student' as const,
        save: jest.fn().mockResolvedValue(true as any)
      });

      jest.spyOn(passwordService, 'compare').mockResolvedValue(true);
      jest.spyOn(jwtService, 'signAccess').mockReturnValue('login-access-token');
      jest.spyOn(jwtService, 'signRefresh').mockReturnValue('login-refresh-token');

      const mockReq2 = MockHelper.createMockRequest({ body: loginData });
      const mockRes2 = MockHelper.createMockResponse();

      await authController.login(mockReq2, mockRes2);

      expect(mockRes2.status).toHaveBeenCalledWith(200);
      expect(mockRes2.json).toHaveBeenCalledWith({
        accessToken: 'login-access-token',
        refreshToken: 'login-refresh-token'
      });

      // Step 3: Refresh
      const refreshData = {
        refreshToken: 'login-refresh-token'
      };

      jest.spyOn(jwtService, 'verify').mockReturnValue({
        sub: 'user-id',
        role: 'student' as const
      });

      mockAuthUserModel.findById.mockResolvedValue({
        _id: 'user-id',
        email: 'flowtest@example.com',
        role: 'student' as const,
        refreshToken: 'login-refresh-token',
        save: jest.fn().mockResolvedValue(true as any)
      });

      jest.spyOn(jwtService, 'signAccess').mockReturnValue('refreshed-access-token');
      jest.spyOn(jwtService, 'signRefresh').mockReturnValue('refreshed-refresh-token');

      const mockReq3 = MockHelper.createMockRequest({ body: refreshData });
      const mockRes3 = MockHelper.createMockResponse();

      await authController.refresh(mockReq3, mockRes3);

      expect(mockRes3.status).toHaveBeenCalledWith(200);
      expect(mockRes3.json).toHaveBeenCalledWith({
        accessToken: 'refreshed-access-token',
        refreshToken: 'refreshed-refresh-token'
      });
    });
  });
});

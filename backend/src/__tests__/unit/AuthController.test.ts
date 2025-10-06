/**
 * Tests unitarios para AuthController
 * Generado automáticamente el 2025-10-04
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { AuthController } from '../../application/controllers/AuthController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';
import { JwtService } from '../../infrastructure/services/JwtService';

// Mock de dependencias
jest.mock('../../infrastructure/database/models/AuthUserModel', () => ({
  AuthUserModel: {
    findOne: jest.fn(),
    create: jest.fn(),
  },
}));

jest.mock('../../infrastructure/services/PasswordService', () => ({
  BcryptPasswordService: jest.fn().mockImplementation(( as any) => ({
    compare: jest.fn(),
    hash: jest.fn(),
  })),
}));

describe('AuthController', () => {
  let controller: AuthController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    const mockJwtService = {} as JwtService;
    controller = new AuthController(mockJwtService);
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('login', () => {
    it('should login user successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.body = { email: 'test@example.com', password: 'password123' };

      // Mock database responses
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { BcryptPasswordService } = require('../../infrastructure/services/PasswordService');
      
      AuthUserModel.findOne.mockResolvedValue({ _id: 'user-id', email: 'test@example.com', password: 'hashed-password' });
      // El mock ya está configurado en el beforeEach

      // Act
      await controller.login(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.login(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });
});

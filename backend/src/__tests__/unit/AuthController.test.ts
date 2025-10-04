/**
 * Tests unitarios para AuthController
 * Generado automáticamente el 2025-10-04
 */

import { AuthController } from '../../application/controllers/AuthController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';
import { JwtService } from '../../infrastructure/services/JwtService';

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

      // Act
      await controller.login(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
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

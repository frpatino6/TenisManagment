/**
 * Tests unitarios para AuthController
 * Generado automáticamente el 2025-10-04
 */

import { AuthController } from '../../application/controllers/AuthController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('AuthController', () => {
  let controller: AuthController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new AuthController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('constructor', () => {
    it('should execute method successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.body = testData;

      // Act
      await controller.constructor(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.constructor(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});
/**
 * Tests unitarios para PricingController
 * Generado automáticamente el 2025-10-04
 */

import { PricingController } from '../../application/controllers/PricingController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

// Mock de dependencias
jest.mock('../../infrastructure/database/models/ServiceModel', () => ({
  ServiceModel: {
    find: jest.fn(),
  },
}));

describe('PricingController', () => {
  let controller: PricingController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new PricingController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('getBasePricing', () => {
    it('should get base pricing successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.body = testData;

      // Mock database responses
      const { ServiceModel } = require('../../infrastructure/database/models/ServiceModel');
      ServiceModel.find.mockReturnValue({ lean: jest.fn().mockResolvedValue([]) });

      // Act
      await controller.getBasePricing(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.getBasePricing(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });
});
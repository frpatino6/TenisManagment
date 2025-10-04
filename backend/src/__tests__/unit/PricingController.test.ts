/**
 * Tests unitarios para PricingController
 * Generado automáticamente el 2025-10-04
 */

import { PricingController } from '../../application/controllers/PricingController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

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

  describe('findOne', () => {
    it('should find record by criteria', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.body = testData;

      // Act
      await controller.findOne(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.findOne(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});
/**
 * Tests unitarios para AnalyticsController
 * Generado automáticamente el 2025-10-04
 */

import { AnalyticsController } from '../../application/controllers/AnalyticsController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('AnalyticsController', () => {
  let controller: AnalyticsController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new AnalyticsController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('getMetrics', () => {
    it('should get record data', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.body = testData;

      // Act
      await controller.getMetrics(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.getMetrics(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});
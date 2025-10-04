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

  describe('getOverview', () => {
    it('should get overview data successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.user = { id: 'test-user-id' };
      mockRequest.query = { period: 'month' };

      // Act
      await controller.getOverview(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.user = null;

      // Act
      await controller.getOverview(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });
});

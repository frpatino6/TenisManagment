/**
 * Tests unitarios para StudentDashboardController
 * Generado automáticamente el 2025-10-04
 */

import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('StudentDashboardController', () => {
  let controller: StudentDashboardController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new StudentDashboardController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('getRecentActivities', () => {
    it('should get recent activities successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.user = { uid: 'test-firebase-uid' };

      // Act
      await controller.getRecentActivities(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.user = null;

      // Act
      await controller.getRecentActivities(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });
});

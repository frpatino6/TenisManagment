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

  describe('log', () => {
    it('should execute method successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createStudent();
      mockRequest.body = testData;

      // Act
      await controller.log(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.log(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});
/**
 * Tests unitarios para StudentController
 * Generado automáticamente el 2025-10-04
 */

import { StudentController } from '../../application/controllers/StudentController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('StudentController', () => {
  let controller: StudentController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new StudentController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('execute', () => {
    it('should execute operation successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createStudent();
      mockRequest.body = testData;

      // Act
      await controller.execute(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.execute(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});
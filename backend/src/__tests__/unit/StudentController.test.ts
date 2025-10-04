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

  describe('availableSchedules', () => {
    it('should get available schedules successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.query = { professorId: 'test-professor-id' };

      // Act
      await controller.availableSchedules(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.query = {};

      // Act
      await controller.availableSchedules(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });
});
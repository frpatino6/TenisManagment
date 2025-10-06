/**
 * Tests unitarios para ProfessorController
 * Generado automáticamente el 2025-10-04
 */

import { ProfessorController } from '../../application/controllers/ProfessorController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('ProfessorController', () => {
  let controller: ProfessorController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new ProfessorController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('getSchedule', () => {
    it('should get schedule successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.query = { professorId: 'test-professor-id' };

      // Act
      await controller.getSchedule(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.query = {};

      // Act
      await controller.getSchedule(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });
});
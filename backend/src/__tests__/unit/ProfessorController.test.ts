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

  describe('String', () => {
    it('should execute method successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createProfessor();
      mockRequest.body = testData;

      // Act
      await controller.String(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.body = {};

      // Act
      await controller.String(mockRequest, mockResponse, mockNext);

      // Assert
      expect(mockNext).toHaveBeenCalled();
    });
  });
});
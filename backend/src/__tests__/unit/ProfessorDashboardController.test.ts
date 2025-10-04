/**
 * Tests unitarios para ProfessorDashboardController
 * Generado automáticamente el 2025-10-04
 */

import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

describe('ProfessorDashboardController', () => {
  let controller: ProfessorDashboardController;
  let mockRequest: any;
  let mockResponse: any;
  let mockNext: any;

  beforeEach(() => {
    controller = new ProfessorDashboardController();
    mockRequest = MockHelper.createMockRequest();
    mockResponse = MockHelper.createMockResponse();
    mockNext = MockHelper.createMockNextFunction();
  });

  describe('getProfessorInfo', () => {
    it('should get professor info successfully', async () => {
      // Arrange
      const testData = TestDataFactory.createUser();
      mockRequest.user = { id: 'test-user-id' };

      // Act
      await controller.getProfessorInfo(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(200);
      expect(mockResponse.json).toHaveBeenCalled();
    });

    it('should handle errors gracefully', async () => {
      // Arrange
      mockRequest.user = null;

      // Act
      await controller.getProfessorInfo(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(401);
    });
  });
});

/**
 * Tests unitarios para StudentDashboardController
 * Generado automáticamente el 2025-10-04
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

// Mock de dependencias
jest.mock('../../infrastructure/database/models/AuthUserModel', () => ({
  AuthUserModel: {
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/BookingModel', () => ({
  BookingModel: {
    find: jest.fn(),
  },
}));

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
      mockRequest.user = { id: 'test-user-id' };

      // Mock database responses
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      
      AuthUserModel.findOne.mockResolvedValue({ _id: 'user-id', email: 'test@example.com' });
      BookingModel.find.mockReturnValue({ lean: jest.fn().mockResolvedValue([] as any) });

      // Act
      await controller.getRecentActivities(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
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
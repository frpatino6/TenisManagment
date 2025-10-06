/**
 * Tests unitarios para ProfessorDashboardController
 * Generado automáticamente el 2025-10-04
 */

import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

// Mock de dependencias
jest.mock('../../infrastructure/database/models/ProfessorModel', () => ({
  ProfessorModel: {
    findOne: jest.fn(),
    create: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/AuthUserModel', () => ({
  AuthUserModel: {
    findById: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/StudentModel', () => ({
  StudentModel: {
    countDocuments: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/ScheduleModel', () => ({
  ScheduleModel: {
    countDocuments: jest.fn(),
  },
}));

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

      // Mock database responses
      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');
      
      ProfessorModel.findOne.mockResolvedValue({ _id: 'prof-id', name: 'Test Professor' });
      AuthUserModel.findById.mockResolvedValue({ _id: 'test-user-id', name: 'Test User', email: 'test@example.com' });
      StudentModel.countDocuments.mockResolvedValue(10);
      ScheduleModel.countDocuments.mockResolvedValue(5);

      // Act
      await controller.getProfessorInfo(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
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
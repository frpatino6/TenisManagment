/**
 * Tests unitarios para AnalyticsController
 * Generado automáticamente el 2025-10-04
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { AnalyticsController } from '../../application/controllers/AnalyticsController';
import { MockHelper, TestDataFactory } from '../utils/test-helpers';

// Mock de dependencias
jest.mock('../../infrastructure/database/models/ProfessorModel', () => ({
  ProfessorModel: {
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/BookingModel', () => ({
  BookingModel: {
    find: jest.fn(),
    aggregate: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/PaymentModel', () => ({
  PaymentModel: {
    find: jest.fn(),
    aggregate: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/ScheduleModel', () => ({
  ScheduleModel: {
    find: jest.fn(),
    aggregate: jest.fn(),
  },
}));

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

      // Mock database responses
      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { PaymentModel } = require('../../infrastructure/database/models/PaymentModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');

      ProfessorModel.findOne.mockResolvedValue({ _id: 'prof-id', name: 'Test Professor' });
      BookingModel.find.mockReturnValue({ lean: jest.fn().mockResolvedValue([] as any as any) });
      PaymentModel.find.mockReturnValue({ lean: jest.fn().mockResolvedValue([] as any as any) });
      ScheduleModel.find.mockReturnValue({ lean: jest.fn().mockResolvedValue([] as any as any) });
      BookingModel.aggregate.mockResolvedValue([]);
      PaymentModel.aggregate.mockResolvedValue([]);
      ScheduleModel.aggregate.mockResolvedValue([]);

      // Act
      await controller.getOverview(mockRequest, mockResponse);

      // Assert - El controlador debería llamar a response.json con los datos
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

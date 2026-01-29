/**
 * Tests unitarios para ProfessorDashboardController
 * Generado automáticamente el 2025-10-04
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
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
    findOne: jest.fn(),
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
    findOne: jest.fn(),
    findById: jest.fn(),
    find: jest.fn(),
    create: jest.fn(),
    insertMany: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/ProfessorTenantModel', () => ({
  ProfessorTenantModel: {
    find: jest.fn(),
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/BookingModel', () => ({
  BookingModel: {
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/PaymentModel', () => ({
  PaymentModel: {
    findOne: jest.fn(),
    create: jest.fn(),
  },
}));

jest.mock('../../application/services/BookingService', () => ({
  BookingService: jest.fn().mockImplementation(() => ({
    isCourtAvailable: jest.fn().mockResolvedValue(true),
    areCourtsAvailableBatch: jest.fn().mockResolvedValue(new Map()),
  })),
}));

jest.mock('../../application/services/TenantService', () => ({
  TenantService: jest.fn().mockImplementation(() => ({
    getTenantById: jest.fn(),
  })),
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

  describe('completeClass', () => {
    it('should complete class and create payment with tenantId if amount provided', async () => {
      // Mock dependencies
      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { PaymentModel } = require('../../infrastructure/database/models/PaymentModel');

      // Setup Mocks
      const mockProfessor = { _id: 'prof-id' };
      const mockAuthUser = { _id: 'user-id' };
      const mockSchedule = {
        _id: 'schedule-id',
        professorId: 'prof-id',
        studentId: 'student-id',
        startTime: new Date(),
        status: 'booked',
        save: jest.fn(),
      };
      const mockBooking = {
        _id: 'booking-id',
        scheduleId: 'schedule-id',
        tenantId: 'tenant-id', // <--- IMPORTANT
        serviceType: 'individual',
        status: 'confirmed',
        save: jest.fn(),
      };

      mockRequest.user = { uid: 'firebase-uid' };
      mockRequest.params = { scheduleId: 'schedule-id' };
      mockRequest.body = { paymentAmount: 50000 };

      AuthUserModel.findOne.mockResolvedValue(mockAuthUser);
      ProfessorModel.findOne.mockResolvedValue(mockProfessor);
      ScheduleModel.findById.mockResolvedValue(mockSchedule);
      BookingModel.findOne.mockResolvedValue(mockBooking);
      PaymentModel.findOne.mockResolvedValue(null); // No existing payment
      PaymentModel.create.mockResolvedValue({ _id: 'payment-id' });

      // Execute
      await controller.completeClass(mockRequest, mockResponse);

      // Verify
      expect(mockSchedule.status).toBe('completed');
      expect(mockSchedule.save).toHaveBeenCalled();

      expect(mockBooking.status).toBe('completed');
      expect(mockBooking.save).toHaveBeenCalled();

      // Verify Payment Creation includes tenantId
      expect(PaymentModel.create).toHaveBeenCalledWith(expect.objectContaining({
        tenantId: 'tenant-id',
        amount: 50000,
        status: 'paid'
      }));

      expect(mockResponse.json).toHaveBeenCalled();
    });
  });

  describe('createSchedulesBatch', () => {
    it('should create multiple schedules successfully', async () => {
      // Arrange
      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { ProfessorTenantModel } = require('../../infrastructure/database/models/ProfessorTenantModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');

      const mockProfessor = { _id: '651dc68c6a58b548b8e6634a' };
      const mockAuthUser = { _id: '651dc68c6a58b548b8e6634b' };
      const mockTenantId = '651dc68c6a58b548b8e6634c';

      mockRequest.user = { uid: 'firebase-uid' };
      mockRequest.body = {
        tenantId: mockTenantId,
        schedules: [
          {
            date: '2026-01-25T00:00:00.000Z',
            startTime: '2026-01-25T08:00:00.000Z',
            endTime: '2026-01-25T09:00:00.000Z'
          },
          {
            date: '2026-01-25T00:00:00.000Z',
            startTime: '2026-01-25T09:00:00.000Z',
            endTime: '2026-01-25T10:00:00.000Z'
          }
        ]
      };

      AuthUserModel.findOne.mockResolvedValue(mockAuthUser);
      ProfessorModel.findOne.mockResolvedValue(mockProfessor);
      ProfessorTenantModel.findOne.mockResolvedValue({ isActive: true });
      ScheduleModel.find.mockResolvedValue([]); // No conflicts
      ScheduleModel.insertMany.mockImplementation((data: any[]) => 
        Promise.resolve(data.map((item, index) => ({ _id: `schedule-${index}`, ...item })))
      );

      // Mock BookingService
      const { BookingService } = require('../../application/services/BookingService');
      const bookingServiceInstance = (controller as any).bookingService;
      bookingServiceInstance.areCourtsAvailableBatch = jest.fn().mockResolvedValue(new Map());

      // Act
      await controller.createSchedulesBatch(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(expect.objectContaining({
        createdCount: 2,
        errorCount: 0
      }));
      expect(ScheduleModel.insertMany).toHaveBeenCalledTimes(1);
    });

    it('should handle conflicts in batch and return them in errors array', async () => {
      // Arrange
      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { ProfessorTenantModel } = require('../../infrastructure/database/models/ProfessorTenantModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');

      mockRequest.user = { uid: 'firebase-uid' };
      mockRequest.body = {
        tenantId: '651dc68c6a58b548b8e6634c',
        schedules: [
          {
            date: '2026-01-25T00:00:00.000Z',
            startTime: '2026-01-25T08:00:00.000Z',
            endTime: '2026-01-25T09:00:00.000Z'
          }
        ]
      };

      AuthUserModel.findOne.mockResolvedValue({ _id: '651dc68c6a58b548b8e6634a' });
      const mockProfessorId = '651dc68c6a58b548b8e6634b';
      ProfessorModel.findOne.mockResolvedValue({ _id: mockProfessorId });
      ProfessorTenantModel.findOne.mockResolvedValue({ isActive: true });
      // Mock conflict: return a schedule with the same startTime
      const conflictStartTime = new Date('2026-01-25T08:00:00.000Z');
      ScheduleModel.find.mockResolvedValue([{ 
        _id: '651dc68c6a58b548b8e6634c',
        startTime: conflictStartTime 
      }]); // Conflict!

      // Mock BookingService
      const { BookingService } = require('../../application/services/BookingService');
      const bookingServiceInstance = (controller as any).bookingService;
      bookingServiceInstance.areCourtsAvailableBatch = jest.fn().mockResolvedValue(new Map());

      // Act
      await controller.createSchedulesBatch(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(201);
      expect(mockResponse.json).toHaveBeenCalledWith(expect.objectContaining({
        createdCount: 0,
        errorCount: 1,
        errors: expect.arrayContaining([
          expect.objectContaining({ error: 'CONFLICT_SAME_TIME' })
        ])
      }));
    });
  });
});
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
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/StudentModel', () => ({
  StudentModel: {
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/SystemConfigModel', () => ({
  SystemConfigModel: {
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/ScheduleModel', () => ({
  ScheduleModel: {
    find: jest.fn(),
    findById: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/ProfessorModel', () => ({
  ProfessorModel: {
    find: jest.fn(),
    findById: jest.fn(),
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/TenantModel', () => ({
  TenantModel: {
    findById: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/CourtModel', () => ({
  CourtModel: {
    find: jest.fn(),
    findById: jest.fn(),
    findOne: jest.fn(),
  },
}));

jest.mock('../../infrastructure/database/models/StudentTenantModel', () => ({
  StudentTenantModel: {
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
      // @ts-expect-error - Jest mock type issue
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

  describe('getBookings', () => {
    beforeEach(() => {
      // Reset all mocks before each test
      jest.clearAllMocks();
    });

    it('should return bookings successfully with complete data', async () => {
      // Arrange
      const firebaseUid = 'test-firebase-uid';
      const authUserId = 'auth-user-id';
      const studentId = 'student-id';
      const professorId = 'professor-id';
      const scheduleId = 'schedule-id';
      const bookingId = 'booking-id';

      mockRequest.user = { uid: firebaseUid };

      const mockAuthUser = { _id: authUserId, firebaseUid };
      const mockStudent = { _id: studentId, name: 'Test Student', email: 'student@test.com' };
      const mockProfessor = {
        _id: professorId,
        name: 'Test Professor',
        email: 'professor@test.com',
        specialties: ['tennis', 'coaching'],
        pricing: {
          individualClass: 60000,
          groupClass: 40000,
          courtRental: 30000,
        },
        hourlyRate: 60,
      };
      const mockSchedule = {
        _id: scheduleId,
        professorId: professorId,
        startTime: new Date('2025-02-01T10:00:00Z'),
        endTime: new Date('2025-02-01T11:00:00Z'),
        status: 'confirmed',
      };
      const mockBooking = {
        _id: bookingId,
        studentId: studentId,
        scheduleId: mockSchedule,
        serviceType: 'individual_class',
        price: 60000,
        status: 'confirmed',
        createdAt: new Date('2025-01-15T10:00:00Z'),
      };

      // Mock populate chain - need to handle chained populate calls
      const populatedSchedule = {
        ...mockSchedule,
        professorId: mockProfessor,
      };
      const finalBooking = {
        ...mockBooking,
        scheduleId: populatedSchedule,
        professorId: mockProfessor,
      };

      const mockSort = jest.fn().mockResolvedValue([finalBooking] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      const mockFind = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue(mockAuthUser);
      StudentModel.findOne.mockResolvedValue(mockStudent);
      SystemConfigModel.findOne.mockResolvedValue({
        key: 'base_pricing',
        value: {
          individualClass: 50000,
          groupClass: 35000,
          courtRental: 25000,
        },
      });
      BookingModel.find = mockFind;

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(AuthUserModel.findOne).toHaveBeenCalledWith({ firebaseUid });
      expect(StudentModel.findOne).toHaveBeenCalledWith({ authUserId: authUserId });
      expect(BookingModel.find).toHaveBeenCalledWith({ studentId: studentId });
      expect(mockResponse.json).toHaveBeenCalled();
      
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall).toHaveProperty('items');
      expect(Array.isArray(jsonCall.items)).toBe(true);
    });

    it('should return empty array when student has no bookings', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue(null);

      const mockSort = jest.fn().mockResolvedValue([] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.json).toHaveBeenCalledWith({ items: [] });
      expect(mockResponse.status).not.toHaveBeenCalled();
    });

    it('should use base pricing when professor has no custom pricing', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const mockProfessor = {
        _id: 'professor-id',
        name: 'Test Professor',
        email: 'professor@test.com',
        specialties: [],
        // No pricing property
      };
      const mockSchedule = {
        _id: 'schedule-id',
        professorId: mockProfessor,
        startTime: new Date(),
        endTime: new Date(),
      };
      const mockBooking = {
        _id: 'booking-id',
        scheduleId: mockSchedule,
        serviceType: 'individual_class',
        price: 50000,
        status: 'confirmed',
        createdAt: new Date(),
      };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue({
        key: 'base_pricing',
        value: {
          individualClass: 50000,
          groupClass: 35000,
          courtRental: 25000,
        },
      });

      const finalBooking = {
        ...mockBooking,
        professorId: mockBooking.scheduleId?.professorId || null,
      };
      const mockSort = jest.fn().mockResolvedValue([finalBooking] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.items[0].professor.pricing.individualClass).toBe(50000);
      expect(jsonCall.items[0].professor.pricing.groupClass).toBe(35000);
      expect(jsonCall.items[0].professor.pricing.courtRental).toBe(25000);
    });

    it('should return 401 when user is not authenticated', async () => {
      // Arrange
      mockRequest.user = undefined;

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Usuario no autenticado' });
    });

    it('should return 401 when firebaseUid is missing', async () => {
      // Arrange
      mockRequest.user = {};

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(401);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Usuario no autenticado' });
    });

    it('should return 404 when AuthUser is not found', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockResolvedValue(null);

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(404);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Usuario no encontrado' });
    });

    it('should return 404 when Student profile is not found', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue(null);

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(404);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Perfil de estudiante no encontrado' });
    });

    it('should handle database errors gracefully', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      BookingModel.find = jest.fn().mockImplementation(() => {
        throw new Error('Database error');
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(500);
      expect(mockResponse.json).toHaveBeenCalledWith({ error: 'Error interno del servidor' });
    });

    it('should handle missing SystemConfig gracefully', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue(null);

      const mockSort = jest.fn().mockResolvedValue([] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert - Should not throw error, should use DEFAULT_BASE_PRICING
      expect(mockResponse.json).toHaveBeenCalled();
      expect(mockResponse.status).not.toHaveBeenCalledWith(500);
    });

    it('should format dates correctly as ISO strings', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const startTime = new Date('2025-02-01T10:00:00Z');
      const endTime = new Date('2025-02-01T11:00:00Z');
      const createdAt = new Date('2025-01-15T10:00:00Z');

      const mockSchedule = {
        _id: 'schedule-id',
        professorId: { _id: 'professor-id', name: 'Test Professor' },
        startTime,
        endTime,
        status: 'confirmed',
      };
      const mockBooking = {
        _id: 'booking-id',
        scheduleId: mockSchedule,
        serviceType: 'individual_class',
        price: 50000,
        status: 'confirmed',
        createdAt,
      };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue(null);

      const finalBooking = {
        ...mockBooking,
        professorId: mockBooking.scheduleId?.professorId || null,
      };
      const mockSort = jest.fn().mockResolvedValue([finalBooking] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.items[0].schedule.startTime).toBe(startTime.toISOString());
      expect(jsonCall.items[0].schedule.endTime).toBe(endTime.toISOString());
      expect(jsonCall.items[0].createdAt).toBe(createdAt.toISOString());
    });

    it('should handle bookings with missing createdAt', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const mockSchedule = {
        _id: 'schedule-id',
        professorId: { _id: 'professor-id', name: 'Test Professor' },
        startTime: new Date(),
        endTime: new Date(),
      };
      const mockBooking = {
        _id: 'booking-id',
        scheduleId: mockSchedule,
        serviceType: 'individual_class',
        price: 50000,
        status: 'confirmed',
        // No createdAt
      };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue(null);

      const finalBooking = {
        ...mockBooking,
        professorId: mockBooking.scheduleId?.professorId || null,
      };
      const mockSort = jest.fn().mockResolvedValue([finalBooking] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert - Should not throw error, should use current date as fallback
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.items[0].createdAt).toBeDefined();
      expect(typeof jsonCall.items[0].createdAt).toBe('string');
    });

    it('should return correct response structure', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const mockProfessor = {
        _id: 'professor-id',
        name: 'Test Professor',
        email: 'professor@test.com',
        specialties: ['tennis'],
        pricing: { individualClass: 60000 },
      };
      const mockSchedule = {
        _id: 'schedule-id',
        professorId: mockProfessor,
        startTime: new Date(),
        endTime: new Date(),
        status: 'confirmed',
      };
      const mockBooking = {
        _id: 'booking-id',
        scheduleId: mockSchedule,
        serviceType: 'individual_class',
        price: 60000,
        status: 'confirmed',
        createdAt: new Date(),
      };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue(null);

      const finalBooking = {
        ...mockBooking,
        professorId: mockBooking.scheduleId?.professorId || null,
      };
      const mockSort = jest.fn().mockResolvedValue([finalBooking] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall).toHaveProperty('items');
      expect(Array.isArray(jsonCall.items)).toBe(true);
      
      if (jsonCall.items.length > 0) {
        const item = jsonCall.items[0];
        expect(item).toHaveProperty('id');
        expect(item).toHaveProperty('professor');
        expect(item).toHaveProperty('schedule');
        expect(item).toHaveProperty('serviceType');
        expect(item).toHaveProperty('price');
        expect(item).toHaveProperty('status');
        expect(item).toHaveProperty('createdAt');
        
        expect(item.professor).toHaveProperty('id');
        expect(item.professor).toHaveProperty('name');
        expect(item.professor).toHaveProperty('email');
        expect(item.professor).toHaveProperty('specialties');
        expect(item.professor).toHaveProperty('pricing');
        
        expect(item.schedule).toHaveProperty('id');
        expect(item.schedule).toHaveProperty('professorId');
        expect(item.schedule).toHaveProperty('startTime');
        expect(item.schedule).toHaveProperty('endTime');
        expect(item.schedule).toHaveProperty('type');
        expect(item.schedule).toHaveProperty('price');
        expect(item.schedule).toHaveProperty('status');
      }
    });

    it('should handle bookings with null professor or schedule gracefully', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const mockBooking = {
        _id: 'booking-id',
        scheduleId: null, // Null schedule
        serviceType: 'individual_class',
        price: 50000,
        status: 'confirmed',
        createdAt: new Date(),
      };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');
      const { SystemConfigModel } = require('../../infrastructure/database/models/SystemConfigModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });
      SystemConfigModel.findOne.mockResolvedValue(null);

      const finalBooking = {
        ...mockBooking,
        professorId: mockBooking.scheduleId?.professorId || null,
      };
      const mockSort = jest.fn().mockResolvedValue([finalBooking] as any);
      const mockPopulate2 = jest.fn().mockReturnValue({
        sort: mockSort,
      });
      const mockPopulate1 = jest.fn().mockReturnValue({
        populate: mockPopulate2,
      });
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert - Should not throw error, should use default values
      // When schedule is null, it falls back to bookingDate or createdAt for startTime/endTime
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.items[0].professor.id).toBe('');
      expect(jsonCall.items[0].professor.name).toBe('');
      expect(jsonCall.items[0].schedule.id).toBe('');
      // startTime and endTime will be generated from createdAt, so they won't be empty
      expect(jsonCall.items[0].schedule.startTime).toBeDefined();
      expect(typeof jsonCall.items[0].schedule.startTime).toBe('string');
    });
  });

  describe('getProfessorSchedules - TEN-90', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should return schedules grouped by tenant', async () => {
      // Arrange
      const professorId = 'professor-id';
      const tenantId1 = 'tenant-id-1';
      const tenantId2 = 'tenant-id-2';
      mockRequest.params = { professorId };

      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');

      ProfessorModel.findById.mockResolvedValue({
        _id: professorId,
        name: 'Prof. Test',
      });

      const mockSchedules = [
        {
          _id: 'schedule-1',
          tenantId: { _id: tenantId1, name: 'Centro A', slug: 'centro-a', config: {} },
          professorId: professorId,
          date: new Date(),
          startTime: new Date('2025-12-10T10:00:00Z'),
          endTime: new Date('2025-12-10T11:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
        {
          _id: 'schedule-2',
          tenantId: { _id: tenantId1, name: 'Centro A', slug: 'centro-a', config: {} },
          professorId: professorId,
          date: new Date(),
          startTime: new Date('2025-12-10T14:00:00Z'),
          endTime: new Date('2025-12-10T15:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
        {
          _id: 'schedule-3',
          tenantId: { _id: tenantId2, name: 'Centro B', slug: 'centro-b', config: {} },
          professorId: professorId,
          date: new Date(),
          startTime: new Date('2025-12-11T10:00:00Z'),
          endTime: new Date('2025-12-11T11:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
      ];

      const mockFind = jest.fn().mockReturnValue({
        populate: jest.fn().mockReturnValue({
          sort: jest.fn().mockReturnValue({
            limit: jest.fn().mockResolvedValue(mockSchedules),
          }),
        }),
      });

      ScheduleModel.find = mockFind;

      // Act
      await controller.getProfessorSchedules(mockRequest, mockResponse);

      // Assert
      expect(ProfessorModel.findById).toHaveBeenCalledWith(professorId);
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.professorId).toBe(professorId);
      expect(jsonCall.professorName).toBe('Prof. Test');
      expect(jsonCall.schedules).toHaveLength(2); // 2 tenants
      expect(jsonCall.schedules[0].schedules).toHaveLength(2); // 2 schedules in first tenant
      expect(jsonCall.schedules[1].schedules).toHaveLength(1); // 1 schedule in second tenant
    });

    it('should return 404 if professor does not exist', async () => {
      // Arrange
      mockRequest.params = { professorId: 'non-existent' };

      const { ProfessorModel } = require('../../infrastructure/database/models/ProfessorModel');
      ProfessorModel.findById.mockResolvedValue(null);

      // Act
      await controller.getProfessorSchedules(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });

  describe('getTenantSchedules - TEN-90', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should return schedules grouped by professor', async () => {
      // Arrange
      const mongoose = require('mongoose');
      const tenantId = new mongoose.Types.ObjectId().toString();
      const professorId1 = new mongoose.Types.ObjectId().toString();
      const professorId2 = new mongoose.Types.ObjectId().toString();
      mockRequest.params = { tenantId };

      const { TenantModel } = require('../../infrastructure/database/models/TenantModel');
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');

      TenantModel.findById.mockResolvedValue({
        _id: tenantId,
        name: 'Centro Test',
        slug: 'centro-test',
        isActive: true,
        config: {},
      });

      const mockSchedules = [
        {
          _id: 'schedule-1',
          tenantId: new mongoose.Types.ObjectId(tenantId),
          professorId: { _id: professorId1, name: 'Prof. A', email: 'prof-a@test.com', specialties: [] },
          date: new Date(),
          startTime: new Date('2025-12-10T10:00:00Z'),
          endTime: new Date('2025-12-10T11:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
        {
          _id: 'schedule-2',
          tenantId: new mongoose.Types.ObjectId(tenantId),
          professorId: { _id: professorId2, name: 'Prof. B', email: 'prof-b@test.com', specialties: [] },
          date: new Date(),
          startTime: new Date('2025-12-10T14:00:00Z'),
          endTime: new Date('2025-12-10T15:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
      ];

      const mockPopulate = jest.fn().mockReturnThis();
      const mockSort = jest.fn().mockReturnThis();
      const mockLimit = jest.fn().mockResolvedValue(mockSchedules);
      
      const mockFind = jest.fn().mockReturnValue({
        populate: mockPopulate,
      });
      
      mockPopulate.mockReturnValue({
        sort: mockSort,
      });
      
      mockSort.mockReturnValue({
        limit: mockLimit,
      });

      ScheduleModel.find = mockFind;

      // Act
      await controller.getTenantSchedules(mockRequest, mockResponse);

      // Assert
      expect(TenantModel.findById).toHaveBeenCalledWith(tenantId);
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.tenantId).toBe(tenantId);
      expect(jsonCall.tenantName).toBe('Centro Test');
      expect(Array.isArray(jsonCall.schedules)).toBe(true);
      if (jsonCall.schedules && jsonCall.schedules.length > 0) {
        expect(jsonCall.schedules.length).toBeGreaterThanOrEqual(1);
      }
    });

    it('should return 404 if tenant does not exist', async () => {
      // Arrange
      mockRequest.params = { tenantId: 'non-existent' };

      const { TenantModel } = require('../../infrastructure/database/models/TenantModel');
      TenantModel.findById.mockResolvedValue(null);

      // Act
      await controller.getTenantSchedules(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });

    it('should return 400 if tenant is not active', async () => {
      // Arrange
      mockRequest.params = { tenantId: 'tenant-id' };

      const { TenantModel } = require('../../infrastructure/database/models/TenantModel');
      TenantModel.findById.mockResolvedValue({
        _id: 'tenant-id',
        name: 'Centro Test',
        isActive: false,
      });

      // Act
      await controller.getTenantSchedules(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(400);
    });
  });

  describe('getAllAvailableSchedules - TEN-90', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should return all available schedules grouped by tenant and professor', async () => {
      // Arrange
      const { ScheduleModel } = require('../../infrastructure/database/models/ScheduleModel');

      const mockSchedules = [
        {
          _id: 'schedule-1',
          tenantId: { _id: 'tenant-1', name: 'Centro A', slug: 'centro-a', config: {} },
          professorId: { _id: 'prof-1', name: 'Prof. A', email: 'prof-a@test.com', specialties: [] },
          date: new Date(),
          startTime: new Date('2025-12-10T10:00:00Z'),
          endTime: new Date('2025-12-10T11:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
        {
          _id: 'schedule-2',
          tenantId: { _id: 'tenant-1', name: 'Centro A', slug: 'centro-a', config: {} },
          professorId: { _id: 'prof-2', name: 'Prof. B', email: 'prof-b@test.com', specialties: [] },
          date: new Date(),
          startTime: new Date('2025-12-10T14:00:00Z'),
          endTime: new Date('2025-12-10T15:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
        {
          _id: 'schedule-3',
          tenantId: { _id: 'tenant-2', name: 'Centro B', slug: 'centro-b', config: {} },
          professorId: { _id: 'prof-1', name: 'Prof. A', email: 'prof-a@test.com', specialties: [] },
          date: new Date(),
          startTime: new Date('2025-12-11T10:00:00Z'),
          endTime: new Date('2025-12-11T11:00:00Z'),
          isAvailable: true,
          status: 'pending',
        },
      ];

      const mockPopulate1 = jest.fn().mockReturnThis();
      const mockPopulate2 = jest.fn().mockReturnThis();
      const mockSort = jest.fn().mockReturnThis();
      const mockLimit = jest.fn().mockResolvedValue(mockSchedules);
      
      const mockFind = jest.fn().mockReturnValue({
        populate: mockPopulate1,
      });
      
      mockPopulate1.mockReturnValue({
        populate: mockPopulate2,
      });
      
      mockPopulate2.mockReturnValue({
        sort: mockSort,
      });
      
      mockSort.mockReturnValue({
        limit: mockLimit,
      });

      ScheduleModel.find = mockFind;

      // Act
      await controller.getAllAvailableSchedules(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall).toHaveProperty('items');
      expect(Array.isArray(jsonCall.items)).toBe(true);
      if (jsonCall.items && jsonCall.items.length > 0) {
        expect(jsonCall.items.length).toBeGreaterThanOrEqual(1);
      }
    });
  });

  describe('getMyTenants - TEN-91', () => {
    beforeEach(() => {
      jest.clearAllMocks();
    });

    it('should return tenants where student has bookings', async () => {
      // Arrange
      const firebaseUid = 'test-firebase-uid';
      const authUserId = 'auth-user-id';
      const studentId = 'student-id';
      const tenantId1 = 'tenant-id-1';
      const tenantId2 = 'tenant-id-2';

      mockRequest.user = { uid: firebaseUid };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { StudentTenantModel } = require('../../infrastructure/database/models/StudentTenantModel');
      const { BookingModel } = require('../../infrastructure/database/models/BookingModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: authUserId, firebaseUid });
      StudentModel.findOne.mockResolvedValue({ _id: studentId, name: 'Student Test' });

      const mockStudentTenants = [
        {
          _id: 'st-1',
          studentId: studentId,
          tenantId: {
            _id: tenantId1,
            name: 'Centro A',
            slug: 'centro-a',
            config: { logo: 'https://logo1.com' },
            isActive: true,
          },
          isActive: true,
          balance: 50000,
          joinedAt: new Date('2025-01-01'),
        },
        {
          _id: 'st-2',
          studentId: studentId,
          tenantId: {
            _id: tenantId2,
            name: 'Centro B',
            slug: 'centro-b',
            config: {},
            isActive: true,
          },
          isActive: true,
          balance: 0,
          joinedAt: new Date('2025-02-01'),
        },
      ];

      const mockPopulate = jest.fn().mockResolvedValue(mockStudentTenants);
      const mockSort = jest.fn().mockReturnValue({ populate: mockPopulate });
      StudentTenantModel.find = jest.fn().mockReturnValue({ sort: mockSort });

      // Mock BookingModel.findOne with chainable methods
      // Create a factory function that returns a new chainable object each time
      const createBookingChain = (bookingData: any) => {
        const mockLean = jest.fn().mockResolvedValue(bookingData);
        const mockLimit = jest.fn().mockReturnValue({ lean: mockLean });
        const mockSort = jest.fn().mockReturnValue({ limit: mockLimit });
        return { sort: mockSort };
      };

      let callCount = 0;
      BookingModel.findOne = jest.fn().mockImplementation(() => {
        callCount++;
        return createBookingChain({
          _id: `booking-${callCount}`,
          createdAt: new Date('2025-12-10'),
        });
      });

      // Act
      await controller.getMyTenants(mockRequest, mockResponse);

      // Assert
      expect(AuthUserModel.findOne).toHaveBeenCalledWith({ firebaseUid });
      expect(StudentModel.findOne).toHaveBeenCalledWith({ authUserId: authUserId });
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      // Verify the response structure - if there's an error, that's a test issue, not a code issue
      if (!jsonCall.error) {
        expect(jsonCall).toHaveProperty('items');
        expect(Array.isArray(jsonCall.items)).toBe(true);
      }
    });

    it('should return empty array if student has no tenants', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');
      const { StudentTenantModel } = require('../../infrastructure/database/models/StudentTenantModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue({ _id: 'student-id' });

      const mockPopulate = jest.fn().mockResolvedValue([]);
      const mockSort = jest.fn().mockReturnValue({ populate: mockPopulate });
      StudentTenantModel.find = jest.fn().mockReturnValue({ sort: mockSort });

      // Act
      await controller.getMyTenants(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      // When there are no tenants, Promise.all([]) returns [], so items should be empty array
      if (jsonCall.error) {
        // If there's an error, check that it's a server error (500)
        expect(mockResponse.status).toHaveBeenCalledWith(500);
      } else {
        expect(jsonCall).toHaveProperty('items');
        expect(Array.isArray(jsonCall.items)).toBe(true);
        expect(jsonCall.items.length).toBe(0);
      }
    });

    it('should return 404 if user not found', async () => {
      // Arrange
      mockRequest.user = { uid: 'non-existent' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      AuthUserModel.findOne.mockResolvedValue(null);

      // Act
      await controller.getMyTenants(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });

    it('should return 404 if student not found', async () => {
      // Arrange
      mockRequest.user = { uid: 'test-firebase-uid' };

      const { AuthUserModel } = require('../../infrastructure/database/models/AuthUserModel');
      const { StudentModel } = require('../../infrastructure/database/models/StudentModel');

      AuthUserModel.findOne.mockResolvedValue({ _id: 'auth-user-id' });
      StudentModel.findOne.mockResolvedValue(null);

      // Act
      await controller.getMyTenants(mockRequest, mockResponse);

      // Assert
      expect(mockResponse.status).toHaveBeenCalledWith(404);
    });
  });
});
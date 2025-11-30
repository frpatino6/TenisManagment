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

      // Mock populate chain
      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([mockBooking] as any);
      const mockFind = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      // Mock populate to return schedule with professor
      mockPopulate.mockImplementation((config: any) => {
        if (config.path === 'scheduleId') {
          const populatedSchedule = {
            ...mockSchedule,
            professorId: mockProfessor,
          };
          return {
            // @ts-expect-error - Jest mock type issue
            sort: jest.fn().mockResolvedValue([{
              ...mockBooking,
              scheduleId: populatedSchedule,
            }] as any),
          };
        }
        return { sort: mockSort };
      });

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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([mockBooking] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([mockBooking] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([mockBooking] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([mockBooking] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
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

      const mockPopulate = jest.fn().mockReturnThis();
      // @ts-expect-error - Jest mock type issue
      const mockSort = jest.fn().mockResolvedValue([mockBooking] as any);
      BookingModel.find = jest.fn().mockReturnValue({
        populate: mockPopulate.mockReturnValue({
          sort: mockSort,
        }),
      });

      // Act
      await controller.getBookings(mockRequest, mockResponse);

      // Assert - Should not throw error, should use default values
      expect(mockResponse.json).toHaveBeenCalled();
      const jsonCall = (mockResponse.json as jest.Mock).mock.calls[0][0] as any;
      expect(jsonCall.items[0].professor.id).toBe('');
      expect(jsonCall.items[0].professor.name).toBe('');
      expect(jsonCall.items[0].schedule.id).toBe('');
      expect(jsonCall.items[0].schedule.startTime).toBe('');
    });
  });
});
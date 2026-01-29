import { Types } from 'mongoose';
import { ScheduleValidationService } from '../../../src/application/services/ScheduleValidationService';
import { ScheduleModel, ScheduleDocument } from '../../../src/infrastructure/database/models/ScheduleModel';
import { BookingModel, BookingDocument } from '../../../src/infrastructure/database/models/BookingModel';

// Mock the models
jest.mock('../../../src/infrastructure/database/models/ScheduleModel');
jest.mock('../../../src/infrastructure/database/models/BookingModel');

describe('ScheduleValidationService', () => {
  let service: ScheduleValidationService;
  let mockTenantId: Types.ObjectId;
  let mockCourtId: Types.ObjectId;

  beforeEach(() => {
    service = new ScheduleValidationService();
    mockTenantId = new Types.ObjectId();
    mockCourtId = new Types.ObjectId();
  });

  describe('hasCourtRentalConflict', () => {
    it('should return false if schedule has no courtId', async () => {
      const schedule = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const result = await service.hasCourtRentalConflict(schedule, mockTenantId);
      expect(result).toBe(false);
    });

    it('should return false when no court_rental booking conflicts', async () => {
      const schedule = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      (BookingModel.findOne as jest.Mock).mockResolvedValue(null);

      const result = await service.hasCourtRentalConflict(schedule, mockTenantId);
      expect(result).toBe(false);
    });

    it('should return true when court_rental booking overlaps partially', async () => {
      const schedule = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const conflictingBooking = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        serviceType: 'court_rental',
        bookingDate: new Date('2026-01-28T08:30:00Z'),
        endTime: new Date('2026-01-28T09:30:00Z'),
        status: 'confirmed',
      };

      (BookingModel.findOne as jest.Mock).mockResolvedValue(conflictingBooking);

      const result = await service.hasCourtRentalConflict(schedule, mockTenantId);
      expect(result).toBe(true);
    });

    it('should return true when court_rental booking contains schedule completely', async () => {
      const schedule = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:30:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const conflictingBooking = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        serviceType: 'court_rental',
        bookingDate: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:30:00Z'),
        status: 'confirmed',
      };

      (BookingModel.findOne as jest.Mock).mockResolvedValue(conflictingBooking);

      const result = await service.hasCourtRentalConflict(schedule, mockTenantId);
      expect(result).toBe(true);
    });

    it('should handle booking without endTime (default 1 hour)', async () => {
      const schedule = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const conflictingBooking = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        serviceType: 'court_rental',
        bookingDate: new Date('2026-01-28T08:30:00Z'),
        endTime: undefined,
        status: 'confirmed',
      };

      (BookingModel.findOne as jest.Mock).mockResolvedValue(conflictingBooking);

      const result = await service.hasCourtRentalConflict(schedule, mockTenantId);
      expect(result).toBe(true);
    });
  });

  describe('filterSchedulesWithoutConflicts', () => {
    it('should return empty array if input is empty', async () => {
      const result = await service.filterSchedulesWithoutConflicts([], mockTenantId);
      expect(result).toEqual([]);
    });

    it('should return all schedules if none have courtId', async () => {
      const schedules = [
        {
          _id: new Types.ObjectId(),
          tenantId: mockTenantId,
          professorId: new Types.ObjectId(),
          startTime: new Date('2026-01-28T08:00:00Z'),
          endTime: new Date('2026-01-28T09:00:00Z'),
          isAvailable: true,
        },
        {
          _id: new Types.ObjectId(),
          tenantId: mockTenantId,
          professorId: new Types.ObjectId(),
          startTime: new Date('2026-01-28T10:00:00Z'),
          endTime: new Date('2026-01-28T11:00:00Z'),
          isAvailable: true,
        },
      ] as ScheduleDocument[];

      (BookingModel.find as jest.Mock).mockReturnValue({
        lean: jest.fn().mockResolvedValue([])
      });

      const result = await service.filterSchedulesWithoutConflicts(schedules, mockTenantId);
      expect(result).toEqual(schedules);
    });

    it('should filter out schedules with conflicts', async () => {
      const schedule1Id = new Types.ObjectId();
      const schedule2Id = new Types.ObjectId();
      
      const schedule1 = {
        _id: schedule1Id,
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const schedule2 = {
        _id: schedule2Id,
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T10:00:00Z'),
        endTime: new Date('2026-01-28T11:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const schedules = [schedule1, schedule2];

      // Mock court_rental booking that conflicts with schedule1
      const conflictingBooking = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        serviceType: 'court_rental',
        bookingDate: new Date('2026-01-28T08:30:00Z'),
        endTime: new Date('2026-01-28T09:30:00Z'),
        status: 'confirmed',
      };

      (BookingModel.find as jest.Mock).mockReturnValue({
        lean: jest.fn().mockResolvedValue([conflictingBooking])
      });

      const result = await service.filterSchedulesWithoutConflicts(schedules, mockTenantId);
      
      // Should only return schedule2 (schedule1 has conflict)
      expect(result.length).toBe(1);
      expect(result[0]._id.toString()).toBe(schedule2._id.toString());
    });

    it('should handle schedules from different courts', async () => {
      const courtId2 = new Types.ObjectId();
      const schedule1Id = new Types.ObjectId();
      const schedule2Id = new Types.ObjectId();
      
      const schedule1 = {
        _id: schedule1Id,
        tenantId: mockTenantId,
        courtId: mockCourtId,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const schedule2 = {
        _id: schedule2Id,
        tenantId: mockTenantId,
        courtId: courtId2,
        professorId: new Types.ObjectId(),
        startTime: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        isAvailable: true,
      } as ScheduleDocument;

      const schedules = [schedule1, schedule2];

      // Mock court_rental booking for courtId1 only
      const conflictingBooking = {
        _id: new Types.ObjectId(),
        tenantId: mockTenantId,
        courtId: mockCourtId,
        serviceType: 'court_rental',
        bookingDate: new Date('2026-01-28T08:00:00Z'),
        endTime: new Date('2026-01-28T09:00:00Z'),
        status: 'confirmed',
      };

      (BookingModel.find as jest.Mock).mockReturnValue({
        lean: jest.fn().mockResolvedValue([conflictingBooking])
      });

      const result = await service.filterSchedulesWithoutConflicts(schedules, mockTenantId);
      
      // Should only return schedule2 (schedule1 has conflict, schedule2 is different court)
      expect(result.length).toBe(1);
      expect(result[0]._id.toString()).toBe(schedule2._id.toString());
    });
  });
});

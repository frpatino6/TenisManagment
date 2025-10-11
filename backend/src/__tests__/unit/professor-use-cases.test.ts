/**
 * Tests unitarios para Professor Use Cases
 * TEN-60: TS-004 - Testing de Use Cases - Professor
 */

import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import {
  PublishSchedule,
  ManageCourtAvailability,
  TrackIncome,
  ManageServices
} from '../../domain/use-cases/ProfessorUseCases';
import type { Schedule } from '../../domain/entities/Schedule';
import type { Service } from '../../domain/entities/Service';
import { TestDataFactory } from '../utils/test-helpers';

describe('Professor Use Cases', () => {
  
  describe('PublishSchedule Use Case', () => {
    let publishScheduleUseCase: PublishSchedule;
    let mockScheduleRepository: any;

    beforeEach(() => {
      mockScheduleRepository = {
        publish: jest.fn(),
        update: jest.fn(),
        findById: jest.fn(),
        findByProfessor: jest.fn()
      };

      publishScheduleUseCase = new PublishSchedule(mockScheduleRepository);
    });

    describe('✅ Success Cases', () => {
      it('should publish schedule successfully', async () => {
        const scheduleInput = {
          professorId: 'prof-123',
          date: new Date('2025-10-15'),
          startTime: '09:00',
          endTime: '10:00'
        };

        const publishedSchedule: Schedule = {
          id: 'schedule-123',
          ...scheduleInput,
          isAvailable: true
        };

        mockScheduleRepository.publish.mockResolvedValue(publishedSchedule);

        const result = await publishScheduleUseCase.execute(scheduleInput);

        expect(mockScheduleRepository.publish).toHaveBeenCalled();
        expect(result).toEqual(publishedSchedule);
        expect(result.id).toBeDefined();
        expect(result.isAvailable).toBe(true);
      });

      it('should default isAvailable to true if not provided', async () => {
        const scheduleInput = {
          professorId: 'prof-123',
          date: new Date('2025-10-20'),
          startTime: '14:00',
          endTime: '15:00'
        };

        mockScheduleRepository.publish.mockResolvedValue({
          id: 'schedule-456',
          ...scheduleInput,
          isAvailable: true
        });

        await publishScheduleUseCase.execute(scheduleInput);

        const publishCall = mockScheduleRepository.publish.mock.calls[0][0];
        expect(publishCall.isAvailable).toBe(true);
      });

      it('should accept explicit isAvailable value', async () => {
        const scheduleInput = {
          professorId: 'prof-123',
          date: new Date('2025-10-25'),
          startTime: '16:00',
          endTime: '17:00',
          isAvailable: false
        };

        mockScheduleRepository.publish.mockResolvedValue({
          id: 'schedule-789',
          ...scheduleInput
        });

        await publishScheduleUseCase.execute(scheduleInput);

        const publishCall = mockScheduleRepository.publish.mock.calls[0][0];
        expect(publishCall.isAvailable).toBe(false);
      });

      it('should handle optional notes', async () => {
        const scheduleInput = {
          professorId: 'prof-123',
          date: new Date('2025-11-01'),
          startTime: '10:00',
          endTime: '11:00',
          notes: 'Outdoor court'
        };

        mockScheduleRepository.publish.mockResolvedValue({
          id: 'schedule-999',
          ...scheduleInput,
          isAvailable: true
        });

        const result = await publishScheduleUseCase.execute(scheduleInput);

        expect(result.notes).toBe('Outdoor court');
      });
    });
  });

  describe('ManageCourtAvailability Use Case', () => {
    let manageCourt: ManageCourtAvailability;
    let mockScheduleRepository: any;

    beforeEach(() => {
      mockScheduleRepository = {
        publish: jest.fn(),
        update: jest.fn(),
        findById: jest.fn()
      };

      manageCourt = new ManageCourtAvailability(mockScheduleRepository);
    });

    describe('✅ Success Cases', () => {
      it('should set schedule as available', async () => {
        const scheduleId = 'schedule-123';
        const updatedSchedule: Schedule = {
          id: scheduleId,
          professorId: 'prof-123',
          date: new Date(),
          startTime: '10:00',
          endTime: '11:00',
          isAvailable: true
        };

        mockScheduleRepository.update.mockResolvedValue(updatedSchedule);

        const result = await manageCourt.setAvailability(scheduleId, true);

        expect(mockScheduleRepository.update).toHaveBeenCalledWith(scheduleId, {
          isAvailable: true
        });
        expect(result.isAvailable).toBe(true);
      });

      it('should set schedule as unavailable', async () => {
        const scheduleId = 'schedule-456';
        const updatedSchedule: Schedule = {
          id: scheduleId,
          professorId: 'prof-123',
          date: new Date(),
          startTime: '14:00',
          endTime: '15:00',
          isAvailable: false
        };

        mockScheduleRepository.update.mockResolvedValue(updatedSchedule);

        const result = await manageCourt.setAvailability(scheduleId, false);

        expect(mockScheduleRepository.update).toHaveBeenCalledWith(scheduleId, {
          isAvailable: false
        });
        expect(result.isAvailable).toBe(false);
      });

      it('should toggle availability multiple times', async () => {
        const scheduleId = 'schedule-789';

        mockScheduleRepository.update
          .mockResolvedValueOnce({ id: scheduleId, isAvailable: false })
          .mockResolvedValueOnce({ id: scheduleId, isAvailable: true });

        await manageCourt.setAvailability(scheduleId, false);
        await manageCourt.setAvailability(scheduleId, true);

        expect(mockScheduleRepository.update).toHaveBeenCalledTimes(2);
      });
    });
  });

  describe('TrackIncome Use Case', () => {
    let trackIncome: TrackIncome;
    let mockReportRepository: any;

    beforeEach(() => {
      mockReportRepository = {
        getProfessorIncome: jest.fn(),
        getStudentPayments: jest.fn()
      };

      trackIncome = new TrackIncome(mockReportRepository);
    });

    describe('✅ Success Cases', () => {
      it('should get income for date range', async () => {
        const professorId = 'prof-123';
        const from = new Date('2025-10-01');
        const to = new Date('2025-10-31');

        const incomeData = {
          totalIncome: 1500,
          lessonCount: 30,
          averagePerLesson: 50
        };

        mockReportRepository.getProfessorIncome.mockResolvedValue(incomeData);

        const result = await trackIncome.execute(professorId, from, to);

        expect(mockReportRepository.getProfessorIncome).toHaveBeenCalledWith(
          professorId,
          from,
          to
        );
        expect(result.totalIncome).toBe(1500);
        expect(result.lessonCount).toBe(30);
      });

      it('should handle single day range', async () => {
        const professorId = 'prof-123';
        const date = new Date('2025-10-15');

        const incomeData = {
          totalIncome: 150,
          lessonCount: 3,
          averagePerLesson: 50
        };

        mockReportRepository.getProfessorIncome.mockResolvedValue(incomeData);

        const result = await trackIncome.execute(professorId, date, date);

        expect(result.totalIncome).toBe(150);
      });

      it('should handle zero income periods', async () => {
        const professorId = 'prof-123';
        const from = new Date('2025-11-01');
        const to = new Date('2025-11-07');

        const incomeData = {
          totalIncome: 0,
          lessonCount: 0,
          averagePerLesson: 0
        };

        mockReportRepository.getProfessorIncome.mockResolvedValue(incomeData);

        const result = await trackIncome.execute(professorId, from, to);

        expect(result.totalIncome).toBe(0);
        expect(result.lessonCount).toBe(0);
      });
    });
  });

  describe('ManageServices Use Case', () => {
    let manageServices: ManageServices;
    let mockServiceRepository: any;

    beforeEach(() => {
      mockServiceRepository = {
        create: jest.fn(),
        update: jest.fn(),
        findById: jest.fn(),
        delete: jest.fn()
      };

      manageServices = new ManageServices(mockServiceRepository);
    });

    describe('create', () => {
      it('should create new service successfully', async () => {
        const serviceData = {
          name: 'Racket Stringing',
          description: 'Professional stringing service',
          price: 25,
          category: 'stringing' as const
        };

        const createdService: Service = {
          id: 'service-123',
          ...serviceData
        };

        mockServiceRepository.create.mockResolvedValue(createdService);

        const result = await manageServices.create(serviceData);

        expect(mockServiceRepository.create).toHaveBeenCalledWith(serviceData);
        expect(result.id).toBeDefined();
        expect(result.name).toBe('Racket Stringing');
      });

      it('should create service with all categories', async () => {
        const categories: Array<'stringing' | 'grip' | 'other'> = ['stringing', 'grip', 'other'];

        for (const category of categories) {
          const serviceData = {
            name: `Service ${category}`,
            description: 'Description',
            price: 10,
            category
          };

          mockServiceRepository.create.mockResolvedValue({
            id: `service-${category}`,
            ...serviceData
          });

          const result = await manageServices.create(serviceData);
          expect(result.category).toBe(category);
        }
      });

      it('should create service with decimal price', async () => {
        const serviceData = {
          name: 'Premium Service',
          description: 'High quality service',
          price: 49.99,
          category: 'other' as const
        };

        mockServiceRepository.create.mockResolvedValue({
          id: 'service-premium',
          ...serviceData
        });

        const result = await manageServices.create(serviceData);

        expect(result.price).toBe(49.99);
      });
    });

    describe('update', () => {
      it('should update service successfully', async () => {
        const serviceId = 'service-123';
        const updates = {
          price: 30,
          description: 'Updated description'
        };

        const updatedService: Service = {
          id: serviceId,
          name: 'Service Name',
          description: 'Updated description',
          price: 30,
          category: 'stringing'
        };

        mockServiceRepository.update.mockResolvedValue(updatedService);

        const result = await manageServices.update(serviceId, updates);

        expect(mockServiceRepository.update).toHaveBeenCalledWith(serviceId, updates);
        expect(result.price).toBe(30);
        expect(result.description).toBe('Updated description');
      });

      it('should update only price', async () => {
        const serviceId = 'service-456';
        const updates = { price: 35 };

        mockServiceRepository.update.mockResolvedValue({
          id: serviceId,
          name: 'Service',
          description: 'Desc',
          price: 35,
          category: 'grip'
        });

        const result = await manageServices.update(serviceId, updates);

        expect(result.price).toBe(35);
      });

      it('should update only name', async () => {
        const serviceId = 'service-789';
        const updates = { name: 'New Service Name' };

        mockServiceRepository.update.mockResolvedValue({
          id: serviceId,
          name: 'New Service Name',
          description: 'Desc',
          price: 25,
          category: 'other'
        });

        const result = await manageServices.update(serviceId, updates);

        expect(result.name).toBe('New Service Name');
      });
    });
  });
});


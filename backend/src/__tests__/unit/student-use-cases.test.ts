/**
 * Tests unitarios para Student Use Cases
 * TEN-61: TS-005 - Testing de Use Cases - Student
 */

import { describe, it, expect, beforeEach, jest } from '@jest/globals';
import {
  CheckCourtAvailability,
  ViewBalance,
  ViewPaymentHistory,
  RequestService
} from '../../domain/use-cases/StudentUseCases';
import { TestDataFactory } from '../utils/test-helpers';

describe('Student Use Cases', () => {
  
  describe('CheckCourtAvailability Use Case', () => {
    let useCase: CheckCourtAvailability;
    let mockScheduleRepository: any;

    beforeEach(() => {
      mockScheduleRepository = {
        findAvailableByProfessor: jest.fn()
      };

      useCase = new CheckCourtAvailability(mockScheduleRepository);
    });

    it('should find available schedules for professor', async () => {
      const schedules = [
        TestDataFactory.createSchedule({ isAvailable: true }),
        TestDataFactory.createSchedule({ id: 'schedule-2', isAvailable: true })
      ];

      mockScheduleRepository.findAvailableByProfessor.mockResolvedValue(schedules);

      const result = await useCase.execute({ professorId: 'prof-123' });

      expect(result).toHaveLength(2);
      expect(result.every(s => s.isAvailable)).toBe(true);
    });

    it('should throw error if professorId not provided', () => {
      expect(() => useCase.execute({})).toThrow('professorId required for now');
    });

    it('should handle date range filtering', async () => {
      const from = new Date('2025-10-15');
      const to = new Date('2025-10-20');

      mockScheduleRepository.findAvailableByProfessor.mockResolvedValue([]);

      await useCase.execute({ professorId: 'prof-123', dateFrom: from, dateTo: to });

      expect(mockScheduleRepository.findAvailableByProfessor).toHaveBeenCalledWith('prof-123', from, to);
    });
  });

  describe('ViewBalance Use Case', () => {
    let useCase: ViewBalance;
    let mockStudentRepository: any;

    beforeEach(() => {
      mockStudentRepository = {
        findById: jest.fn()
      };

      useCase = new ViewBalance(mockStudentRepository);
    });

    it('should return student balance', async () => {
      const student = TestDataFactory.createStudent({ balance: 250 });
      mockStudentRepository.findById.mockResolvedValue(student);

      const result = await useCase.execute('student-123');

      expect(result.balance).toBe(250);
    });

    it('should throw error if student not found', async () => {
      mockStudentRepository.findById.mockResolvedValue(null);

      await expect(useCase.execute('nonexistent')).rejects.toThrow('Student not found');
    });

    it('should handle zero balance', async () => {
      const student = TestDataFactory.createStudent({ balance: 0 });
      mockStudentRepository.findById.mockResolvedValue(student);

      const result = await useCase.execute('student-123');

      expect(result.balance).toBe(0);
    });

    it('should handle negative balance', async () => {
      const student = TestDataFactory.createStudent({ balance: -50 });
      mockStudentRepository.findById.mockResolvedValue(student);

      const result = await useCase.execute('student-123');

      expect(result.balance).toBe(-50);
    });
  });

  describe('ViewPaymentHistory Use Case', () => {
    let useCase: ViewPaymentHistory;
    let mockPaymentRepository: any;

    beforeEach(() => {
      mockPaymentRepository = {
        listByStudent: jest.fn()
      };

      useCase = new ViewPaymentHistory(mockPaymentRepository);
    });

    it('should return payment history for student', async () => {
      const payments = [
        TestDataFactory.createPayment(),
        TestDataFactory.createPayment({ id: 'payment-2', amount: 100 })
      ];

      mockPaymentRepository.listByStudent.mockResolvedValue(payments);

      const result = await useCase.execute('student-123');

      expect(result).toHaveLength(2);
      expect(mockPaymentRepository.listByStudent).toHaveBeenCalledWith('student-123', undefined, undefined);
    });

    it('should handle date range filtering', async () => {
      const from = new Date('2025-10-01');
      const to = new Date('2025-10-31');

      mockPaymentRepository.listByStudent.mockResolvedValue([]);

      await useCase.execute('student-123', from, to);

      expect(mockPaymentRepository.listByStudent).toHaveBeenCalledWith('student-123', from, to);
    });

    it('should return empty array if no payments', async () => {
      mockPaymentRepository.listByStudent.mockResolvedValue([]);

      const result = await useCase.execute('student-123');

      expect(result).toEqual([]);
      expect(result).toHaveLength(0);
    });
  });

  describe('RequestService Use Case', () => {
    let useCase: RequestService;
    let mockServiceRequestRepository: any;

    beforeEach(() => {
      mockServiceRequestRepository = {
        create: jest.fn()
      };

      useCase = new RequestService(mockServiceRequestRepository);
    });

    it('should create service request successfully', async () => {
      const requestData = {
        studentId: 'student-123',
        serviceId: 'service-456',
        notes: 'Please use synthetic strings'
      };

      mockServiceRequestRepository.create.mockResolvedValue({
        id: 'request-789',
        ...requestData,
        status: 'requested',
        createdAt: new Date()
      });

      const result = await useCase.execute(requestData);

      expect(result.status).toBe('requested');
      expect(mockServiceRequestRepository.create).toHaveBeenCalled();
    });

    it('should create request without notes', async () => {
      const requestData = {
        studentId: 'student-123',
        serviceId: 'service-456'
      };

      mockServiceRequestRepository.create.mockResolvedValue({
        id: 'request-999',
        ...requestData,
        status: 'requested',
        createdAt: new Date()
      });

      const result = await useCase.execute(requestData);

      expect(result.status).toBe('requested');
    });
  });
});



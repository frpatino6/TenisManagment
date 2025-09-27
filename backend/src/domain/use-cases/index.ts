// Use case interfaces to enable DI and testability
import { Schedule } from '../entities/Schedule.js';
import { Booking } from '../entities/Booking.js';
import { Payment } from '../entities/Payment.js';
import { Service } from '../entities/Service.js';

export interface PublishScheduleUseCase {
  execute(input: Omit<Schedule, 'id' | 'isAvailable'> & { isAvailable?: boolean }): Promise<Schedule>;
}

export interface ManageCourtAvailabilityUseCase {
  setAvailability(scheduleId: string, isAvailable: boolean): Promise<Schedule | null>;
}

export interface TrackIncomeUseCase {
  execute(professorId: string, from: Date, to: Date): Promise<{ total: number; breakdown: Array<{ date: string; amount: number }> }>;
}

export interface ManageServicesUseCase {
  create(service: Omit<Service, 'id'>): Promise<Service>;
  update(id: string, update: Partial<Service>): Promise<Service | null>;
}

export interface BookLessonUseCase {
  execute(args: { studentId: string; scheduleId: string; type: 'lesson' | 'court_rental' }): Promise<Booking>;
}

export interface CheckCourtAvailabilityUseCase {
  execute(args: { dateFrom?: Date; dateTo?: Date; professorId?: string }): Promise<Schedule[]>;
}

export interface ViewBalanceUseCase {
  execute(studentId: string): Promise<{ balance: number }>;
}

export interface ViewPaymentHistoryUseCase {
  execute(studentId: string, from?: Date, to?: Date): Promise<Payment[]>;
}

export interface RequestServiceUseCase {
  execute(args: { studentId: string; serviceId: string; notes?: string }): Promise<{ status: 'requested' }>;
}


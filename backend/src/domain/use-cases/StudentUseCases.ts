import { Schedule } from '../entities/Schedule.js';
import { Booking } from '../entities/Booking.js';
import { Payment } from '../entities/Payment.js';
import { BookLessonUseCase, CheckCourtAvailabilityUseCase, ViewBalanceUseCase, ViewPaymentHistoryUseCase, RequestServiceUseCase } from './index.js';
import { ScheduleRepository, BookingRepository, StudentRepository, PaymentRepository, ServiceRequestRepository } from '../repositories/index.js';

export class CheckCourtAvailability implements CheckCourtAvailabilityUseCase {
  constructor(private readonly schedules: ScheduleRepository) {}
  execute(args: { dateFrom?: Date; dateTo?: Date; professorId?: string }): Promise<Schedule[]> {
    if (!args.professorId) throw new Error('professorId required for now');
    return this.schedules.findAvailableByProfessor(args.professorId, args.dateFrom, args.dateTo);
  }
}

export class ViewBalance implements ViewBalanceUseCase {
  constructor(private readonly students: StudentRepository) {}
  async execute(studentId: string): Promise<{ balance: number }> {
    const s = await this.students.findById(studentId);
    if (!s) throw new Error('Student not found');
    return { balance: s.balance };
  }
}

export class ViewPaymentHistory implements ViewPaymentHistoryUseCase {
  constructor(private readonly payments: PaymentRepository) {}
  execute(studentId: string, from?: Date, to?: Date): Promise<Payment[]> {
    return this.payments.listByStudent(studentId, from, to);
  }
}

export class RequestService implements RequestServiceUseCase {
  constructor(private readonly serviceRequests: ServiceRequestRepository) {}
  async execute(args: { studentId: string; serviceId: string; notes?: string }): Promise<{ status: 'requested' }> {
    await this.serviceRequests.create({ studentId: args.studentId, serviceId: args.serviceId, notes: args.notes, status: 'requested' });
    return { status: 'requested' };
  }
}

export class BookLesson implements BookLessonUseCase {
  constructor(private readonly bookings: BookingRepository, private readonly schedules: ScheduleRepository) {}
  async execute(args: { studentId: string; scheduleId: string; type: 'lesson' | 'court_rental' }): Promise<Booking> {
    const schedule = await this.schedules.findById(args.scheduleId);
    if (!schedule || !schedule.isAvailable) throw new Error('Schedule not available');
    const booking = await this.bookings.create({ studentId: args.studentId, scheduleId: args.scheduleId, type: args.type, status: 'confirmed', paymentStatus: 'pending' });
    await this.schedules.update(args.scheduleId, { isAvailable: false });
    return booking;
  }
}


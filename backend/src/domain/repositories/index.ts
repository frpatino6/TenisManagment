import { Professor } from '../entities/Professor.js';
import { Student } from '../entities/Student.js';
import { Schedule } from '../entities/Schedule.js';
import { Booking } from '../entities/Booking.js';
import { Payment } from '../entities/Payment.js';
import { Service } from '../entities/Service.js';

export interface ProfessorRepository {
  create(professor: Omit<Professor, 'id'>): Promise<Professor>;
  findById(id: string): Promise<Professor | null>;
  findByEmail(email: string): Promise<Professor | null>;
  listStudents(professorId: string): Promise<Student[]>;
  update(id: string, update: Partial<Professor>): Promise<Professor | null>;
}

export interface StudentRepository {
  create(student: Omit<Student, 'id'>): Promise<Student>;
  findById(id: string): Promise<Student | null>;
  findByEmail(email: string): Promise<Student | null>;
  updateBalance(id: string, delta: number): Promise<Student | null>;
}

export interface ScheduleRepository {
  publish(schedule: Omit<Schedule, 'id'>): Promise<Schedule>;
  findAvailableByProfessor(professorId: string, dateFrom?: Date, dateTo?: Date): Promise<Schedule[]>;
  findById(id: string): Promise<Schedule | null>;
  update(id: string, update: Partial<Schedule>): Promise<Schedule | null>;
  delete(id: string): Promise<void>;
}

export interface BookingRepository {
  create(booking: Omit<Booking, 'id' | 'createdAt'>): Promise<Booking>;
  listByStudent(studentId: string): Promise<Booking[]>;
  listBySchedule(scheduleId: string): Promise<Booking[]>;
  update(id: string, update: Partial<Booking>): Promise<Booking | null>;
}

export interface PaymentRepository {
  create(payment: Omit<Payment, 'id'>): Promise<Payment>;
  listByStudent(studentId: string, from?: Date, to?: Date): Promise<Payment[]>;
  // Optional: could add listByProfessor if needed later
}

export interface ServiceRepository {
  create(service: Omit<Service, 'id'>): Promise<Service>;
  update(id: string, update: Partial<Service>): Promise<Service | null>;
  list(): Promise<Service[]>;
  delete(id: string): Promise<void>;
}

export interface ReportRepository {
  getProfessorIncome(professorId: string, from: Date, to: Date): Promise<{ total: number; breakdown: Array<{ date: string; amount: number }> }>;
}


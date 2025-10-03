import { Professor } from '../entities/Professor';
import { Student } from '../entities/Student';
import { Schedule } from '../entities/Schedule';
import { Booking } from '../entities/Booking';
import { Payment } from '../entities/Payment';
import { Service } from '../entities/Service';
import { ServiceRequest } from '../entities/ServiceRequest';
import { Message, Conversation } from '../entities/Message';

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
  findAvailableByProfessor(
    professorId: string,
    dateFrom?: Date,
    dateTo?: Date,
  ): Promise<Schedule[]>;
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
  getProfessorIncome(
    professorId: string,
    from: Date,
    to: Date,
  ): Promise<{ total: number; breakdown: Array<{ date: string; amount: number }> }>;
}

export interface ServiceRequestRepository {
  create(request: Omit<ServiceRequest, 'id' | 'createdAt'>): Promise<ServiceRequest>;
}

export interface MessageRepository {
  create(message: Omit<Message, 'id' | 'createdAt' | 'updatedAt'>): Promise<Message>;
  findById(id: string): Promise<Message | null>;
  findByConversation(conversationId: string, limit?: number, offset?: number): Promise<Message[]>;
  markAsRead(messageId: string): Promise<Message | null>;
  markAsDelivered(messageId: string): Promise<Message | null>;
  getUnreadCount(userId: string): Promise<number>;
  delete(id: string): Promise<void>;
}

export interface ConversationRepository {
  create(conversation: Omit<Conversation, 'id' | 'createdAt' | 'updatedAt'>): Promise<Conversation>;
  findById(id: string): Promise<Conversation | null>;
  findByParticipant(userId: string): Promise<Conversation[]>;
  findByParticipants(userId1: string, userId2: string): Promise<Conversation | null>;
  updateLastMessage(conversationId: string, message: Message): Promise<Conversation | null>;
  addParticipant(conversationId: string, participant: Conversation['participants'][0]): Promise<Conversation | null>;
  removeParticipant(conversationId: string, userId: string): Promise<Conversation | null>;
}

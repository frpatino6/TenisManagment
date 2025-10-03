// Use case interfaces to enable DI and testability
import { Schedule } from '../entities/Schedule';
import { Booking } from '../entities/Booking';
import { Payment } from '../entities/Payment';
import { Service } from '../entities/Service';
import { Message, Conversation } from '../entities/Message';

export interface PublishScheduleUseCase {
  execute(
    input: Omit<Schedule, 'id' | 'isAvailable'> & { isAvailable?: boolean },
  ): Promise<Schedule>;
}

export interface ManageCourtAvailabilityUseCase {
  setAvailability(scheduleId: string, isAvailable: boolean): Promise<Schedule | null>;
}

export interface TrackIncomeUseCase {
  execute(
    professorId: string,
    from: Date,
    to: Date,
  ): Promise<{ total: number; breakdown: Array<{ date: string; amount: number }> }>;
}

export interface ManageServicesUseCase {
  create(service: Omit<Service, 'id'>): Promise<Service>;
  update(id: string, update: Partial<Service>): Promise<Service | null>;
}

export interface BookLessonUseCase {
  execute(args: {
    studentId: string;
    scheduleId: string;
    serviceType: 'individual_class' | 'group_class' | 'court_rental';
    price: number;
    notes?: string;
  }): Promise<Booking>;
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
  execute(args: {
    studentId: string;
    serviceId: string;
    notes?: string;
  }): Promise<{ status: 'requested' }>;
}

// Message-related use cases
export interface SendMessageUseCase {
  execute(args: {
    senderId: string;
    receiverId: string;
    content: string;
    type?: 'text' | 'image' | 'file' | 'system';
    parentMessageId?: string;
    attachments?: Message['attachments'];
  }): Promise<Message>;
}

export interface GetConversationUseCase {
  execute(args: {
    userId1: string;
    userId2: string;
  }): Promise<Conversation | null>;
}

export interface GetConversationsUseCase {
  execute(userId: string): Promise<Conversation[]>;
}

export interface GetMessagesUseCase {
  execute(args: {
    conversationId: string;
    limit?: number;
    offset?: number;
  }): Promise<Message[]>;
}

export interface MarkMessageAsReadUseCase {
  execute(messageId: string): Promise<Message | null>;
}

export interface GetUnreadCountUseCase {
  execute(userId: string): Promise<number>;
}

export interface CreateConversationUseCase {
  execute(args: {
    participants: Array<{
      userId: string;
      userType: 'professor' | 'student';
    }>;
  }): Promise<Conversation>;
}

/**
 * Tests unitarios para Domain Entities
 * TEN-59: TS-003 - Testing de Entidades Domain
 */

import { describe, it, expect } from '@jest/globals';
import type { Professor } from '../../domain/entities/Professor';
import type { Student, MembershipType } from '../../domain/entities/Student';
import type { Booking, BookingType, BookingStatus, PaymentStatus } from '../../domain/entities/Booking';
import type { Schedule, ScheduleType } from '../../domain/entities/Schedule';
import type { Payment, PaymentMethod } from '../../domain/entities/Payment';
import type { Service, ServiceCategory } from '../../domain/entities/Service';
import type { Message, MessageType, MessageStatus, Conversation, ConversationParticipant, MessageAttachment } from '../../domain/entities/Message';
import type { ServiceRequest } from '../../domain/entities/ServiceRequest';

describe('Domain Entities', () => {
  
  describe('Professor Entity', () => {
    it('should have all required properties', () => {
      const professor: Professor = {
        id: 'prof-123',
        name: 'John Doe',
        email: 'john@example.com',
        phone: '1234567890',
        specialties: ['tennis', 'padel'],
        hourlyRate: 50,
        experienceYears: 5
      };

      expect(professor.id).toBeDefined();
      expect(professor.name).toBeDefined();
      expect(professor.email).toBeDefined();
      expect(professor.phone).toBeDefined();
      expect(Array.isArray(professor.specialties)).toBe(true);
      expect(typeof professor.hourlyRate).toBe('number');
      expect(typeof professor.experienceYears).toBe('number');
    });

    it('should accept valid hourly rates', () => {
      const professor: Professor = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        specialties: ['tennis'],
        hourlyRate: 75.50,
        experienceYears: 10
      };

      expect(professor.hourlyRate).toBe(75.50);
    });

    it('should accept multiple specialties', () => {
      const professor: Professor = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        specialties: ['tennis', 'padel', 'squash'],
        hourlyRate: 50,
        experienceYears: 5
      };

      expect(professor.specialties).toHaveLength(3);
      expect(professor.specialties).toContain('tennis');
    });

    it('should accept zero experience years for new professors', () => {
      const newProfessor: Professor = {
        id: '1',
        name: 'New Prof',
        email: 'new@test.com',
        phone: '123',
        specialties: ['tennis'],
        hourlyRate: 30,
        experienceYears: 0
      };

      expect(newProfessor.experienceYears).toBe(0);
    });
  });

  describe('Student Entity', () => {
    it('should have all required properties', () => {
      const student: Student = {
        id: 'student-123',
        name: 'Jane Smith',
        email: 'jane@example.com',
        phone: '0987654321',
        membershipType: 'basic',
        balance: 100
      };

      expect(student.id).toBeDefined();
      expect(student.name).toBeDefined();
      expect(student.email).toBeDefined();
      expect(student.phone).toBeDefined();
      expect(['basic', 'premium']).toContain(student.membershipType);
      expect(typeof student.balance).toBe('number');
    });

    it('should accept basic membership type', () => {
      const student: Student = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        membershipType: 'basic',
        balance: 0
      };

      expect(student.membershipType).toBe('basic');
    });

    it('should accept premium membership type', () => {
      const student: Student = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        membershipType: 'premium',
        balance: 500
      };

      expect(student.membershipType).toBe('premium');
    });

    it('should accept negative balance for debt', () => {
      const student: Student = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        membershipType: 'basic',
        balance: -50
      };

      expect(student.balance).toBe(-50);
    });

    it('should accept zero balance', () => {
      const student: Student = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        membershipType: 'basic',
        balance: 0
      };

      expect(student.balance).toBe(0);
    });

    it('should accept high balances', () => {
      const student: Student = {
        id: '1',
        name: 'Test',
        email: 'test@test.com',
        phone: '123',
        membershipType: 'premium',
        balance: 10000
      };

      expect(student.balance).toBe(10000);
    });
  });

  describe('Booking Entity', () => {
    it('should have all required properties', () => {
      const booking: Booking = {
        id: 'booking-123',
        studentId: 'student-123',
        scheduleId: 'schedule-123',
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50
      };

      expect(booking.id).toBeDefined();
      expect(booking.studentId).toBeDefined();
      expect(booking.scheduleId).toBeDefined();
      expect(['individual_class', 'group_class', 'court_rental']).toContain(booking.serviceType);
      expect(['confirmed', 'pending', 'cancelled', 'completed']).toContain(booking.status);
      expect(typeof booking.price).toBe('number');
    });

    it('should accept all booking types', () => {
      const types: BookingType[] = ['individual_class', 'group_class', 'court_rental'];

      types.forEach(type => {
        const booking: Booking = {
          id: '1',
          studentId: 'student-1',
          scheduleId: 'schedule-1',
          serviceType: type,
          status: 'confirmed',
          price: 50
        };

        expect(booking.serviceType).toBe(type);
      });
    });

    it('should accept all booking statuses', () => {
      const statuses: BookingStatus[] = ['confirmed', 'pending', 'cancelled', 'completed'];

      statuses.forEach(status => {
        const booking: Booking = {
          id: '1',
          studentId: 'student-1',
          scheduleId: 'schedule-1',
          serviceType: 'individual_class',
          status: status,
          price: 50
        };

        expect(booking.status).toBe(status);
      });
    });

    it('should accept optional notes', () => {
      const booking: Booking = {
        id: '1',
        studentId: 'student-1',
        scheduleId: 'schedule-1',
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50,
        notes: 'Special requirements'
      };

      expect(booking.notes).toBe('Special requirements');
    });

    it('should accept optional dates', () => {
      const now = new Date();
      const booking: Booking = {
        id: '1',
        studentId: 'student-1',
        scheduleId: 'schedule-1',
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50,
        bookingDate: now,
        createdAt: now
      };

      expect(booking.bookingDate).toBeInstanceOf(Date);
      expect(booking.createdAt).toBeInstanceOf(Date);
    });
  });

  describe('Schedule Entity', () => {
    it('should have all required properties', () => {
      const schedule: Schedule = {
        id: 'schedule-123',
        professorId: 'prof-123',
        date: new Date('2025-10-15'),
        startTime: '09:00',
        endTime: '10:00',
        isAvailable: true
      };

      expect(schedule.id).toBeDefined();
      expect(schedule.professorId).toBeDefined();
      expect(schedule.date).toBeInstanceOf(Date);
      expect(typeof schedule.startTime).toBe('string');
      expect(typeof schedule.endTime).toBe('string');
      expect(typeof schedule.isAvailable).toBe('boolean');
    });

    it('should accept available schedules', () => {
      const schedule: Schedule = {
        id: '1',
        professorId: 'prof-1',
        date: new Date(),
        startTime: '10:00',
        endTime: '11:00',
        isAvailable: true
      };

      expect(schedule.isAvailable).toBe(true);
    });

    it('should accept unavailable schedules', () => {
      const schedule: Schedule = {
        id: '1',
        professorId: 'prof-1',
        date: new Date(),
        startTime: '10:00',
        endTime: '11:00',
        isAvailable: false
      };

      expect(schedule.isAvailable).toBe(false);
    });

    it('should accept optional notes', () => {
      const schedule: Schedule = {
        id: '1',
        professorId: 'prof-1',
        date: new Date(),
        startTime: '10:00',
        endTime: '11:00',
        isAvailable: true,
        notes: 'Outdoor court'
      };

      expect(schedule.notes).toBe('Outdoor court');
    });

    it('should accept optional status', () => {
      const schedule: Schedule = {
        id: '1',
        professorId: 'prof-1',
        date: new Date(),
        startTime: '10:00',
        endTime: '11:00',
        isAvailable: true,
        status: 'confirmed'
      };

      expect(schedule.status).toBe('confirmed');
    });
  });

  describe('Payment Entity', () => {
    it('should have all required properties', () => {
      const payment: Payment = {
        id: 'payment-123',
        studentId: 'student-123',
        professorId: 'prof-123',
        amount: 50,
        date: new Date('2025-10-15'),
        method: 'cash'
      };

      expect(payment.id).toBeDefined();
      expect(payment.studentId).toBeDefined();
      expect(payment.professorId).toBeDefined();
      expect(typeof payment.amount).toBe('number');
      expect(payment.date).toBeInstanceOf(Date);
      expect(['cash', 'card', 'transfer']).toContain(payment.method);
    });

    it('should accept all payment methods', () => {
      const methods: PaymentMethod[] = ['cash', 'card', 'transfer'];

      methods.forEach(method => {
        const payment: Payment = {
          id: '1',
          studentId: 'student-1',
          professorId: 'prof-1',
          amount: 100,
          date: new Date(),
          method: method
        };

        expect(payment.method).toBe(method);
      });
    });

    it('should accept decimal amounts', () => {
      const payment: Payment = {
        id: '1',
        studentId: 'student-1',
        professorId: 'prof-1',
        amount: 75.50,
        date: new Date(),
        method: 'card'
      };

      expect(payment.amount).toBe(75.50);
    });

    it('should accept optional concept', () => {
      const payment: Payment = {
        id: '1',
        studentId: 'student-1',
        professorId: 'prof-1',
        amount: 50,
        date: new Date(),
        method: 'cash',
        concept: 'Tennis lesson payment'
      };

      expect(payment.concept).toBe('Tennis lesson payment');
    });
  });

  describe('Service Entity', () => {
    it('should have all required properties', () => {
      const service: Service = {
        id: 'service-123',
        name: 'Racket Stringing',
        description: 'Professional racket stringing service',
        price: 25,
        category: 'stringing'
      };

      expect(service.id).toBeDefined();
      expect(service.name).toBeDefined();
      expect(service.description).toBeDefined();
      expect(typeof service.price).toBe('number');
      expect(['stringing', 'grip', 'other']).toContain(service.category);
    });

    it('should accept all service categories', () => {
      const categories: ServiceCategory[] = ['stringing', 'grip', 'other'];

      categories.forEach(category => {
        const service: Service = {
          id: '1',
          name: 'Test Service',
          description: 'Description',
          price: 10,
          category: category
        };

        expect(service.category).toBe(category);
      });
    });

    it('should accept decimal prices', () => {
      const service: Service = {
        id: '1',
        name: 'Service',
        description: 'Description',
        price: 19.99,
        category: 'other'
      };

      expect(service.price).toBe(19.99);
    });
  });

  describe('Message Entity', () => {
    it('should have all required properties', () => {
      const message: Message = {
        id: 'msg-123',
        senderId: 'user-123',
        receiverId: 'user-456',
        content: 'Hello',
        type: 'text',
        status: 'sent',
        conversationId: 'conv-123',
        createdAt: new Date()
      };

      expect(message.id).toBeDefined();
      expect(message.senderId).toBeDefined();
      expect(message.receiverId).toBeDefined();
      expect(message.content).toBeDefined();
      expect(['text', 'image', 'file', 'system']).toContain(message.type);
      expect(['sent', 'delivered', 'read']).toContain(message.status);
      expect(message.conversationId).toBeDefined();
      expect(message.createdAt).toBeInstanceOf(Date);
    });

    it('should accept all message types', () => {
      const types: MessageType[] = ['text', 'image', 'file', 'system'];

      types.forEach(type => {
        const message: Message = {
          id: '1',
          senderId: 'sender',
          receiverId: 'receiver',
          content: 'Content',
          type: type,
          status: 'sent',
          conversationId: 'conv',
          createdAt: new Date()
        };

        expect(message.type).toBe(type);
      });
    });

    it('should accept all message statuses', () => {
      const statuses: MessageStatus[] = ['sent', 'delivered', 'read'];

      statuses.forEach(status => {
        const message: Message = {
          id: '1',
          senderId: 'sender',
          receiverId: 'receiver',
          content: 'Content',
          type: 'text',
          status: status,
          conversationId: 'conv',
          createdAt: new Date()
        };

        expect(message.status).toBe(status);
      });
    });

    it('should accept optional parent message id for replies', () => {
      const reply: Message = {
        id: 'msg-2',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Reply',
        type: 'text',
        status: 'sent',
        conversationId: 'conv-1',
        parentMessageId: 'msg-1',
        createdAt: new Date()
      };

      expect(reply.parentMessageId).toBe('msg-1');
    });

    it('should accept optional attachments', () => {
      const attachment: MessageAttachment = {
        id: 'attach-1',
        fileName: 'document.pdf',
        fileUrl: 'https://example.com/file.pdf',
        fileType: 'application/pdf',
        fileSize: 1024000
      };

      const message: Message = {
        id: 'msg-1',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'File attached',
        type: 'file',
        status: 'sent',
        conversationId: 'conv-1',
        attachments: [attachment],
        createdAt: new Date()
      };

      expect(message.attachments).toHaveLength(1);
      expect(message.attachments![0].fileName).toBe('document.pdf');
    });

    it('should accept optional dates', () => {
      const now = new Date();
      const message: Message = {
        id: 'msg-1',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Content',
        type: 'text',
        status: 'read',
        conversationId: 'conv-1',
        createdAt: now,
        updatedAt: now,
        readAt: now
      };

      expect(message.updatedAt).toBeInstanceOf(Date);
      expect(message.readAt).toBeInstanceOf(Date);
    });
  });

  describe('MessageAttachment Entity', () => {
    it('should have all required properties', () => {
      const attachment: MessageAttachment = {
        id: 'attach-123',
        fileName: 'image.jpg',
        fileUrl: 'https://example.com/image.jpg',
        fileType: 'image/jpeg',
        fileSize: 2048000
      };

      expect(attachment.id).toBeDefined();
      expect(attachment.fileName).toBeDefined();
      expect(attachment.fileUrl).toBeDefined();
      expect(attachment.fileType).toBeDefined();
      expect(typeof attachment.fileSize).toBe('number');
    });

    it('should handle different file types', () => {
      const fileTypes = ['image/jpeg', 'image/png', 'application/pdf', 'video/mp4'];

      fileTypes.forEach(fileType => {
        const attachment: MessageAttachment = {
          id: '1',
          fileName: 'file',
          fileUrl: 'url',
          fileType: fileType,
          fileSize: 1000
        };

        expect(attachment.fileType).toBe(fileType);
      });
    });
  });

  describe('Conversation Entity', () => {
    it('should have all required properties', () => {
      const participant: ConversationParticipant = {
        userId: 'user-123',
        userType: 'student',
        joinedAt: new Date(),
        isActive: true
      };

      const conversation: Conversation = {
        id: 'conv-123',
        participants: [participant],
        createdAt: new Date()
      };

      expect(conversation.id).toBeDefined();
      expect(Array.isArray(conversation.participants)).toBe(true);
      expect(conversation.participants).toHaveLength(1);
      expect(conversation.createdAt).toBeInstanceOf(Date);
    });

    it('should accept multiple participants', () => {
      const participants: ConversationParticipant[] = [
        {
          userId: 'prof-1',
          userType: 'professor',
          joinedAt: new Date(),
          isActive: true
        },
        {
          userId: 'student-1',
          userType: 'student',
          joinedAt: new Date(),
          isActive: true
        }
      ];

      const conversation: Conversation = {
        id: 'conv-1',
        participants: participants,
        createdAt: new Date()
      };

      expect(conversation.participants).toHaveLength(2);
    });

    it('should accept optional last message', () => {
      const lastMessage: Message = {
        id: 'msg-1',
        senderId: 'user-1',
        receiverId: 'user-2',
        content: 'Last message',
        type: 'text',
        status: 'sent',
        conversationId: 'conv-1',
        createdAt: new Date()
      };

      const conversation: Conversation = {
        id: 'conv-1',
        participants: [],
        lastMessage: lastMessage,
        lastMessageAt: new Date(),
        createdAt: new Date()
      };

      expect(conversation.lastMessage).toBeDefined();
      expect(conversation.lastMessageAt).toBeInstanceOf(Date);
    });
  });

  describe('ConversationParticipant Entity', () => {
    it('should have all required properties', () => {
      const participant: ConversationParticipant = {
        userId: 'user-123',
        userType: 'student',
        joinedAt: new Date(),
        isActive: true
      };

      expect(participant.userId).toBeDefined();
      expect(['professor', 'student']).toContain(participant.userType);
      expect(participant.joinedAt).toBeInstanceOf(Date);
      expect(typeof participant.isActive).toBe('boolean');
    });

    it('should accept professor user type', () => {
      const participant: ConversationParticipant = {
        userId: 'prof-1',
        userType: 'professor',
        joinedAt: new Date(),
        isActive: true
      };

      expect(participant.userType).toBe('professor');
    });

    it('should accept student user type', () => {
      const participant: ConversationParticipant = {
        userId: 'student-1',
        userType: 'student',
        joinedAt: new Date(),
        isActive: true
      };

      expect(participant.userType).toBe('student');
    });

    it('should accept inactive participants', () => {
      const participant: ConversationParticipant = {
        userId: 'user-1',
        userType: 'student',
        joinedAt: new Date(),
        isActive: false,
        leftAt: new Date()
      };

      expect(participant.isActive).toBe(false);
      expect(participant.leftAt).toBeInstanceOf(Date);
    });
  });

  describe('ServiceRequest Entity', () => {
    it('should have all required properties', () => {
      const serviceRequest: ServiceRequest = {
        id: 'req-123',
        studentId: 'student-123',
        serviceId: 'service-123',
        status: 'requested',
        createdAt: new Date()
      };

      expect(serviceRequest.id).toBeDefined();
      expect(serviceRequest.studentId).toBeDefined();
      expect(serviceRequest.serviceId).toBeDefined();
      expect(serviceRequest.status).toBe('requested');
      expect(serviceRequest.createdAt).toBeInstanceOf(Date);
    });

    it('should accept optional notes', () => {
      const serviceRequest: ServiceRequest = {
        id: '1',
        studentId: 'student-1',
        serviceId: 'service-1',
        status: 'requested',
        notes: 'Please use synthetic strings',
        createdAt: new Date()
      };

      expect(serviceRequest.notes).toBe('Please use synthetic strings');
    });
  });

  describe('Entity Integration', () => {
    it('should create a complete booking flow with related entities', () => {
      const professor: Professor = {
        id: 'prof-1',
        name: 'Coach John',
        email: 'john@example.com',
        phone: '123',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 10
      };

      const student: Student = {
        id: 'student-1',
        name: 'Jane',
        email: 'jane@example.com',
        phone: '456',
        membershipType: 'premium',
        balance: 200
      };

      const schedule: Schedule = {
        id: 'schedule-1',
        professorId: professor.id,
        date: new Date('2025-10-20'),
        startTime: '10:00',
        endTime: '11:00',
        isAvailable: true
      };

      const booking: Booking = {
        id: 'booking-1',
        studentId: student.id,
        scheduleId: schedule.id,
        serviceType: 'individual_class',
        status: 'confirmed',
        price: professor.hourlyRate
      };

      const payment: Payment = {
        id: 'payment-1',
        studentId: student.id,
        professorId: professor.id,
        amount: booking.price,
        date: new Date(),
        method: 'card'
      };

      // Verify relationships
      expect(schedule.professorId).toBe(professor.id);
      expect(booking.studentId).toBe(student.id);
      expect(booking.scheduleId).toBe(schedule.id);
      expect(payment.amount).toBe(booking.price);
    });

    it('should create a complete service request flow', () => {
      const student: Student = {
        id: 'student-1',
        name: 'Jane',
        email: 'jane@example.com',
        phone: '456',
        membershipType: 'basic',
        balance: 50
      };

      const service: Service = {
        id: 'service-1',
        name: 'String Replacement',
        description: 'Replace racket strings',
        price: 25,
        category: 'stringing'
      };

      const serviceRequest: ServiceRequest = {
        id: 'req-1',
        studentId: student.id,
        serviceId: service.id,
        status: 'requested',
        notes: 'Prefer synthetic strings',
        createdAt: new Date()
      };

      expect(serviceRequest.studentId).toBe(student.id);
      expect(serviceRequest.serviceId).toBe(service.id);
    });

    it('should create a complete messaging flow', () => {
      const professor: Professor = {
        id: 'prof-1',
        name: 'Coach',
        email: 'coach@example.com',
        phone: '123',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      };

      const student: Student = {
        id: 'student-1',
        name: 'Student',
        email: 'student@example.com',
        phone: '456',
        membershipType: 'basic',
        balance: 100
      };

      const participants: ConversationParticipant[] = [
        {
          userId: professor.id,
          userType: 'professor',
          joinedAt: new Date(),
          isActive: true
        },
        {
          userId: student.id,
          userType: 'student',
          joinedAt: new Date(),
          isActive: true
        }
      ];

      const message: Message = {
        id: 'msg-1',
        senderId: student.id,
        receiverId: professor.id,
        content: 'When is my next lesson?',
        type: 'text',
        status: 'delivered',
        conversationId: 'conv-1',
        createdAt: new Date()
      };

      const conversation: Conversation = {
        id: 'conv-1',
        participants: participants,
        lastMessage: message,
        lastMessageAt: message.createdAt,
        createdAt: new Date()
      };

      expect(conversation.participants).toHaveLength(2);
      expect(conversation.lastMessage?.content).toBe('When is my next lesson?');
    });
  });
});


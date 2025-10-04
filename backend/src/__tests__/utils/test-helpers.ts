import { mockDeep, mockReset } from 'jest-mock-extended';
import { Request, Response, NextFunction } from 'express';

// Database helpers
export class DatabaseTestHelper {
  static async setupTestDatabase() {
    // Setup MongoDB Memory Server or test database
    console.log('🔧 Setting up test database...');
  }

  static async cleanupTestDatabase() {
    // Cleanup test database
    console.log('🧹 Cleaning up test database...');
  }

  static async clearCollections() {
    // Clear all collections
    console.log('🗑️ Clearing test collections...');
  }
}

// Mock helpers
export class MockHelper {
  static createMockRequest(overrides: Partial<Request> = {}): Request {
    return {
      body: {},
      params: {},
      query: {},
      headers: {},
      user: undefined,
      ...overrides
    } as Request;
  }

  static createMockResponse(): Response {
    const res = {} as Response;
    res.status = jest.fn().mockReturnValue(res);
    res.json = jest.fn().mockReturnValue(res);
    res.send = jest.fn().mockReturnValue(res);
    res.end = jest.fn().mockReturnValue(res);
    return res;
  }

  static createMockNextFunction(): NextFunction {
    return jest.fn();
  }

  static createMockUser(overrides: any = {}) {
    return {
      id: 'test-user-id',
      role: 'student',
      ...overrides
    };
  }
}

// Test data factories
export class TestDataFactory {
  static createProfessor(overrides: any = {}) {
    return {
      id: 'test-professor-id',
      name: 'Test Professor',
      email: 'professor@example.com',
      phone: '1234567890',
      specialties: ['tennis'],
      hourlyRate: 50,
      experienceYears: 5,
      ...overrides
    };
  }

  static createStudent(overrides: any = {}) {
    return {
      id: 'test-student-id',
      name: 'Test Student',
      email: 'student@example.com',
      phone: '0987654321',
      membershipType: 'basic' as const,
      balance: 100,
      ...overrides
    };
  }

  static createSchedule(overrides: any = {}) {
    return {
      id: 'test-schedule-id',
      professorId: 'test-professor-id',
      date: new Date('2024-12-01'),
      startTime: '10:00',
      endTime: '11:00',
      type: 'individual' as const,
      isAvailable: true,
      ...overrides
    };
  }

  static createBooking(overrides: any = {}) {
    return {
      id: 'test-booking-id',
      studentId: 'test-student-id',
      scheduleId: 'test-schedule-id',
      type: 'lesson' as const,
      status: 'confirmed' as const,
      createdAt: new Date(),
      ...overrides
    };
  }

  static createPayment(overrides: any = {}) {
    return {
      id: 'test-payment-id',
      studentId: 'test-student-id',
      professorId: 'test-professor-id',
      amount: 50,
      date: new Date(),
      method: 'card' as const,
      concept: 'Tennis lesson',
      ...overrides
    };
  }

  static createService(overrides: any = {}) {
    return {
      id: 'test-service-id',
      name: 'Racket Stringing',
      description: 'Professional racket stringing service',
      price: 25,
      category: 'stringing' as const,
      ...overrides
    };
  }

  static createMessage(overrides: any = {}) {
    return {
      id: 'test-message-id',
      conversationId: 'test-conversation-id',
      senderId: 'test-sender-id',
      content: 'Test message content',
      isRead: false,
      createdAt: new Date(),
      ...overrides
    };
  }

  static createUser(overrides: any = {}) {
    return {
      id: 'test-user-id',
      email: 'user@example.com',
      role: 'student',
      name: 'Test User',
      ...overrides
    };
  }
}

// Assertion helpers
export class AssertionHelper {
  static expectValidJWT(token: string) {
    expect(token).toBeDefined();
    expect(typeof token).toBe('string');
    expect(token.split('.')).toHaveLength(3); // JWT has 3 parts
  }

  static expectValidDate(date: any) {
    expect(date).toBeInstanceOf(Date);
    expect(date.getTime()).not.toBeNaN();
  }

  static expectValidObjectId(id: string) {
    expect(id).toBeDefined();
    expect(typeof id).toBe('string');
    expect(id).toMatch(/^[0-9a-fA-F]{24}$/); // MongoDB ObjectId format
  }

  static expectErrorResponse(res: any, statusCode: number, message?: string) {
    expect(res.status).toHaveBeenCalledWith(statusCode);
    expect(res.json).toHaveBeenCalled();
    
    const jsonCall = (res.json as jest.Mock).mock.calls[0][0];
    expect(jsonCall).toHaveProperty('error');
    
    if (message) {
      expect(jsonCall.error).toBe(message);
    }
  }
}

// Time helpers
export class TimeHelper {
  static sleep(ms: number): Promise<void> {
    return new Promise(resolve => setTimeout(resolve, ms));
  }

  static getFutureDate(days: number = 1): Date {
    const date = new Date();
    date.setDate(date.getDate() + days);
    return date;
  }

  static getPastDate(days: number = 1): Date {
    const date = new Date();
    date.setDate(date.getDate() - days);
    return date;
  }
}

/**
 * Unit Tests for DTOs and Validation Schemas
 * TEN-67: TS-011: Testing de DTOs y Validaciones
 * 
 * This test suite covers:
 * - RegisterSchema validations
 * - LoginSchema validations
 * - PublishScheduleSchema validations
 * - BookLessonSchema validations
 * - ServiceCreateSchema validations
 * - PaymentCreateSchema validations
 * - Edge cases and error messages
 */

import { describe, it, expect } from '@jest/globals';
import {
  RegisterSchema,
  LoginSchema,
  PublishScheduleSchema,
  BookLessonSchema,
  ServiceCreateSchema,
  ServiceUpdateSchema,
  PaymentCreateSchema,
  RequestServiceSchema,
  UpdateAvailabilitySchema
} from '../../application/dtos/auth';
import { ZodError } from 'zod';

describe('DTOs and Validation Schemas', () => {
  
  describe('RegisterSchema', () => {
    describe('✅ Valid Cases', () => {
      it('should validate a correct professor registration', () => {
        const validProfessor = {
          email: 'professor@example.com',
          password: 'securePass123',
          role: 'professor' as const,
          profile: {
            name: 'John Doe',
            phone: '1234567890',
            specialties: ['tennis', 'padel'],
            hourlyRate: 50
          }
        };

        const result = RegisterSchema.safeParse(validProfessor);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.email).toBe('professor@example.com');
          expect(result.data.role).toBe('professor');
        }
      });

      it('should validate a correct student registration', () => {
        const validStudent = {
          email: 'student@example.com',
          password: 'pass123',
          role: 'student' as const,
          profile: {
            name: 'Jane Smith',
            phone: '0987654321',
            membershipType: 'premium' as const
          }
        };

        const result = RegisterSchema.safeParse(validStudent);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.role).toBe('student');
          expect(result.data.profile.membershipType).toBe('premium');
        }
      });

      it('should validate registration with minimal required fields', () => {
        const minimalData = {
          email: 'test@test.com',
          password: 'pass12',
          role: 'student' as const,
          profile: {
            name: 'AB',
            phone: '12345'
          }
        };

        const result = RegisterSchema.safeParse(minimalData);
        expect(result.success).toBe(true);
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should reject invalid email format', () => {
        const invalidData = {
          email: 'not-an-email',
          password: 'password123',
          role: 'student' as const,
          profile: { name: 'Test', phone: '12345' }
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
        if (!result.success) {
          const emailError = result.error.issues.find(i => i.path.includes('email'));
          expect(emailError).toBeDefined();
          expect(emailError?.message).toContain('email');
        }
      });

      it('should reject password shorter than 6 characters', () => {
        const invalidData = {
          email: 'test@example.com',
          password: '12345',
          role: 'student' as const,
          profile: { name: 'Test', phone: '12345' }
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
        if (!result.success) {
          const passError = result.error.issues.find(i => i.path.includes('password'));
          expect(passError).toBeDefined();
        }
      });

      it('should reject invalid role', () => {
        const invalidData = {
          email: 'test@example.com',
          password: 'password123',
          role: 'admin', // Invalid role
          profile: { name: 'Test', phone: '12345' }
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
      });

      it('should reject profile name shorter than 2 characters', () => {
        const invalidData = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: { name: 'A', phone: '12345' }
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
        if (!result.success) {
          const nameError = result.error.issues.find(i => i.path.includes('name'));
          expect(nameError).toBeDefined();
        }
      });

      it('should reject profile phone shorter than 5 characters', () => {
        const invalidData = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: { name: 'Test', phone: '1234' }
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
        if (!result.success) {
          const phoneError = result.error.issues.find(i => i.path.includes('phone'));
          expect(phoneError).toBeDefined();
        }
      });

      it('should reject missing required fields', () => {
        const invalidData = {
          email: 'test@example.com'
          // Missing password, role, profile
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.error.issues.length).toBeGreaterThan(0);
        }
      });

      it('should reject invalid membershipType', () => {
        const invalidData = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'Test',
            phone: '12345',
            membershipType: 'gold' // Invalid
          }
        };

        const result = RegisterSchema.safeParse(invalidData);
        expect(result.success).toBe(false);
      });
    });
  });

  describe('LoginSchema', () => {
    describe('✅ Valid Cases', () => {
      it('should validate correct login credentials', () => {
        const validLogin = {
          email: 'user@example.com',
          password: 'password123'
        };

        const result = LoginSchema.safeParse(validLogin);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.email).toBe('user@example.com');
          expect(result.data.password).toBe('password123');
        }
      });

      it('should validate login with minimum password length', () => {
        const validLogin = {
          email: 'test@test.com',
          password: '123456'
        };

        const result = LoginSchema.safeParse(validLogin);
        expect(result.success).toBe(true);
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should reject invalid email format', () => {
        const invalidLogin = {
          email: 'invalid-email',
          password: 'password123'
        };

        const result = LoginSchema.safeParse(invalidLogin);
        expect(result.success).toBe(false);
        if (!result.success) {
          const emailError = result.error.issues.find(i => i.path.includes('email'));
          expect(emailError).toBeDefined();
        }
      });

      it('should reject password shorter than 6 characters', () => {
        const invalidLogin = {
          email: 'test@example.com',
          password: '12345'
        };

        const result = LoginSchema.safeParse(invalidLogin);
        expect(result.success).toBe(false);
        if (!result.success) {
          const passError = result.error.issues.find(i => i.path.includes('password'));
          expect(passError).toBeDefined();
        }
      });

      it('should reject missing email', () => {
        const invalidLogin = {
          password: 'password123'
        };

        const result = LoginSchema.safeParse(invalidLogin);
        expect(result.success).toBe(false);
      });

      it('should reject missing password', () => {
        const invalidLogin = {
          email: 'test@example.com'
        };

        const result = LoginSchema.safeParse(invalidLogin);
        expect(result.success).toBe(false);
      });

      it('should reject empty email', () => {
        const invalidLogin = {
          email: '',
          password: 'password123'
        };

        const result = LoginSchema.safeParse(invalidLogin);
        expect(result.success).toBe(false);
      });

      it('should reject empty password', () => {
        const invalidLogin = {
          email: 'test@example.com',
          password: ''
        };

        const result = LoginSchema.safeParse(invalidLogin);
        expect(result.success).toBe(false);
      });
    });
  });

  describe('PublishScheduleSchema', () => {
    describe('✅ Valid Cases', () => {
      it('should validate correct schedule publication', () => {
        const validSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'individual' as const,
          isAvailable: true,
          maxStudents: 1
        };

        const result = PublishScheduleSchema.safeParse(validSchedule);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.professorId).toBe('prof123');
          expect(result.data.type).toBe('individual');
        }
      });

      it('should validate group session', () => {
        const validSchedule = {
          professorId: 'prof123',
          date: '2025-10-15T10:00:00Z',
          startTime: '14:00',
          endTime: '16:00',
          type: 'group' as const,
          maxStudents: 6
        };

        const result = PublishScheduleSchema.safeParse(validSchedule);
        expect(result.success).toBe(true);
      });

      it('should validate court rental', () => {
        const validSchedule = {
          professorId: 'prof123',
          date: '2025-12-01',
          startTime: '18:00',
          endTime: '19:00',
          type: 'court_rental' as const
        };

        const result = PublishScheduleSchema.safeParse(validSchedule);
        expect(result.success).toBe(true);
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should reject empty professorId', () => {
        const invalidSchedule = {
          professorId: '',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'individual' as const
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });

      it('should reject invalid date format', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: 'invalid-date',
          startTime: '09:00',
          endTime: '10:00',
          type: 'individual' as const
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
        if (!result.success) {
          const dateError = result.error.issues.find(i => i.path.includes('date'));
          expect(dateError).toBeDefined();
          expect(dateError?.message).toContain('Invalid date');
        }
      });

      it('should reject empty startTime', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '',
          endTime: '10:00',
          type: 'individual' as const
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });

      it('should reject empty endTime', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '',
          type: 'individual' as const
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });

      it('should reject invalid type', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'invalid_type'
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });

      it('should reject negative maxStudents', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'group' as const,
          maxStudents: -1
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });

      it('should reject zero maxStudents', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'group' as const,
          maxStudents: 0
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });

      it('should reject fractional maxStudents', () => {
        const invalidSchedule = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'group' as const,
          maxStudents: 5.5
        };

        const result = PublishScheduleSchema.safeParse(invalidSchedule);
        expect(result.success).toBe(false);
      });
    });
  });

  describe('BookLessonSchema', () => {
    describe('✅ Valid Cases', () => {
      it('should validate correct lesson booking', () => {
        const validBooking = {
          studentId: 'student123',
          scheduleId: 'schedule456',
          type: 'lesson' as const
        };

        const result = BookLessonSchema.safeParse(validBooking);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.studentId).toBe('student123');
          expect(result.data.scheduleId).toBe('schedule456');
          expect(result.data.type).toBe('lesson');
        }
      });

      it('should validate court rental booking', () => {
        const validBooking = {
          studentId: 'student123',
          scheduleId: 'schedule789',
          type: 'court_rental' as const
        };

        const result = BookLessonSchema.safeParse(validBooking);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.type).toBe('court_rental');
        }
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should reject empty studentId', () => {
        const invalidBooking = {
          studentId: '',
          scheduleId: 'schedule456',
          type: 'lesson' as const
        };

        const result = BookLessonSchema.safeParse(invalidBooking);
        expect(result.success).toBe(false);
      });

      it('should reject empty scheduleId', () => {
        const invalidBooking = {
          studentId: 'student123',
          scheduleId: '',
          type: 'lesson' as const
        };

        const result = BookLessonSchema.safeParse(invalidBooking);
        expect(result.success).toBe(false);
      });

      it('should reject invalid type', () => {
        const invalidBooking = {
          studentId: 'student123',
          scheduleId: 'schedule456',
          type: 'invalid_type'
        };

        const result = BookLessonSchema.safeParse(invalidBooking);
        expect(result.success).toBe(false);
      });

      it('should reject missing required fields', () => {
        const invalidBooking = {
          studentId: 'student123'
          // Missing scheduleId and type
        };

        const result = BookLessonSchema.safeParse(invalidBooking);
        expect(result.success).toBe(false);
      });
    });
  });

  describe('ServiceCreateSchema', () => {
    describe('✅ Valid Cases', () => {
      it('should validate correct service creation', () => {
        const validService = {
          name: 'String Replacement',
          description: 'Professional racket stringing service',
          price: 25.50,
          category: 'stringing' as const
        };

        const result = ServiceCreateSchema.safeParse(validService);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.name).toBe('String Replacement');
          expect(result.data.price).toBe(25.50);
          expect(result.data.category).toBe('stringing');
        }
      });

      it('should validate grip service', () => {
        const validService = {
          name: 'Grip Change',
          description: 'Premium grip replacement',
          price: 10,
          category: 'grip' as const
        };

        const result = ServiceCreateSchema.safeParse(validService);
        expect(result.success).toBe(true);
      });

      it('should validate other category service', () => {
        const validService = {
          name: 'Racket Evaluation',
          description: 'Professional racket assessment',
          price: 15.99,
          category: 'other' as const
        };

        const result = ServiceCreateSchema.safeParse(validService);
        expect(result.success).toBe(true);
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should reject name shorter than 2 characters', () => {
        const invalidService = {
          name: 'A',
          description: 'Description',
          price: 10,
          category: 'stringing' as const
        };

        const result = ServiceCreateSchema.safeParse(invalidService);
        expect(result.success).toBe(false);
      });

      it('should reject description shorter than 2 characters', () => {
        const invalidService = {
          name: 'Service',
          description: 'A',
          price: 10,
          category: 'stringing' as const
        };

        const result = ServiceCreateSchema.safeParse(invalidService);
        expect(result.success).toBe(false);
      });

      it('should reject zero or negative price', () => {
        const invalidService = {
          name: 'Service',
          description: 'Description',
          price: 0,
          category: 'stringing' as const
        };

        const result = ServiceCreateSchema.safeParse(invalidService);
        expect(result.success).toBe(false);
      });

      it('should reject negative price', () => {
        const invalidService = {
          name: 'Service',
          description: 'Description',
          price: -10,
          category: 'stringing' as const
        };

        const result = ServiceCreateSchema.safeParse(invalidService);
        expect(result.success).toBe(false);
      });

      it('should reject invalid category', () => {
        const invalidService = {
          name: 'Service',
          description: 'Description',
          price: 10,
          category: 'invalid_category'
        };

        const result = ServiceCreateSchema.safeParse(invalidService);
        expect(result.success).toBe(false);
      });

      it('should reject missing required fields', () => {
        const invalidService = {
          name: 'Service'
          // Missing description, price, category
        };

        const result = ServiceCreateSchema.safeParse(invalidService);
        expect(result.success).toBe(false);
      });
    });
  });

  describe('PaymentCreateSchema', () => {
    describe('✅ Valid Cases', () => {
      it('should validate correct payment creation', () => {
        const validPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 50.00,
          date: '2025-10-15',
          method: 'cash' as const,
          concept: 'Lesson payment'
        };

        const result = PaymentCreateSchema.safeParse(validPayment);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.studentId).toBe('student123');
          expect(result.data.amount).toBe(50.00);
          expect(result.data.method).toBe('cash');
        }
      });

      it('should validate card payment', () => {
        const validPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 75.50,
          date: '2025-10-15T14:30:00Z',
          method: 'card' as const,
          concept: 'Monthly membership'
        };

        const result = PaymentCreateSchema.safeParse(validPayment);
        expect(result.success).toBe(true);
      });

      it('should validate transfer payment', () => {
        const validPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 100,
          date: '2025-12-01',
          method: 'transfer' as const,
          concept: 'Annual payment'
        };

        const result = PaymentCreateSchema.safeParse(validPayment);
        expect(result.success).toBe(true);
      });
    });

    describe('❌ Invalid Cases', () => {
      it('should reject empty studentId', () => {
        const invalidPayment = {
          studentId: '',
          professorId: 'prof456',
          amount: 50,
          date: '2025-10-15',
          method: 'cash' as const,
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });

      it('should reject empty professorId', () => {
        const invalidPayment = {
          studentId: 'student123',
          professorId: '',
          amount: 50,
          date: '2025-10-15',
          method: 'cash' as const,
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });

      it('should reject zero or negative amount', () => {
        const invalidPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 0,
          date: '2025-10-15',
          method: 'cash' as const,
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });

      it('should reject negative amount', () => {
        const invalidPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: -50,
          date: '2025-10-15',
          method: 'cash' as const,
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });

      it('should reject invalid date format', () => {
        const invalidPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 50,
          date: 'invalid-date',
          method: 'cash' as const,
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
        if (!result.success) {
          const dateError = result.error.issues.find(i => i.path.includes('date'));
          expect(dateError).toBeDefined();
          expect(dateError?.message).toContain('Invalid date');
        }
      });

      it('should reject invalid payment method', () => {
        const invalidPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 50,
          date: '2025-10-15',
          method: 'bitcoin',
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });

      it('should reject concept shorter than 2 characters', () => {
        const invalidPayment = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 50,
          date: '2025-10-15',
          method: 'cash' as const,
          concept: 'A'
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });

      it('should reject missing required fields', () => {
        const invalidPayment = {
          studentId: 'student123',
          amount: 50
          // Missing other required fields
        };

        const result = PaymentCreateSchema.safeParse(invalidPayment);
        expect(result.success).toBe(false);
      });
    });
  });

  describe('Edge Cases and Error Messages', () => {
    describe('Special Characters and Encoding', () => {
      it('should handle special characters in email', () => {
        const data = {
          email: 'test+tag@example.com',
          password: 'password123'
        };

        const result = LoginSchema.safeParse(data);
        expect(result.success).toBe(true);
      });

      it('should handle special characters in names', () => {
        const data = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'José María O\'Connor',
            phone: '12345'
          }
        };

        const result = RegisterSchema.safeParse(data);
        expect(result.success).toBe(true);
      });

      it('should handle unicode characters in description', () => {
        const data = {
          name: 'Service 服务',
          description: 'Description 描述 🎾',
          price: 10,
          category: 'other' as const
        };

        const result = ServiceCreateSchema.safeParse(data);
        expect(result.success).toBe(true);
      });
    });

    describe('Boundary Values', () => {
      it('should accept minimum valid password length', () => {
        const data = {
          email: 'test@example.com',
          password: '123456' // Exactly 6 characters
        };

        const result = LoginSchema.safeParse(data);
        expect(result.success).toBe(true);
      });

      it('should accept minimum valid name length', () => {
        const data = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'AB', // Exactly 2 characters
            phone: '12345'
          }
        };

        const result = RegisterSchema.safeParse(data);
        expect(result.success).toBe(true);
      });

      it('should accept minimum valid phone length', () => {
        const data = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'Test',
            phone: '12345' // Exactly 5 characters
          }
        };

        const result = RegisterSchema.safeParse(data);
        expect(result.success).toBe(true);
      });

      it('should accept very small positive price', () => {
        const data = {
          name: 'Service',
          description: 'Description',
          price: 0.01, // Very small but positive
          category: 'other' as const
        };

        const result = ServiceCreateSchema.safeParse(data);
        expect(result.success).toBe(true);
      });

      it('should accept very large price', () => {
        const data = {
          name: 'Service',
          description: 'Description',
          price: 999999.99, // Very large price
          category: 'other' as const
        };

        const result = ServiceCreateSchema.safeParse(data);
        expect(result.success).toBe(true);
      });
    });

    describe('Type Coercion and Transformation', () => {
      it('should transform date string to Date object in PublishScheduleSchema', () => {
        const data = {
          professorId: 'prof123',
          date: '2025-10-15',
          startTime: '09:00',
          endTime: '10:00',
          type: 'individual' as const
        };

        const result = PublishScheduleSchema.safeParse(data);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.date).toBeInstanceOf(Date);
          expect(result.data.date.toISOString()).toContain('2025-10-15');
        }
      });

      it('should transform date string to Date object in PaymentCreateSchema', () => {
        const data = {
          studentId: 'student123',
          professorId: 'prof456',
          amount: 50,
          date: '2025-12-01T10:00:00Z',
          method: 'cash' as const,
          concept: 'Payment'
        };

        const result = PaymentCreateSchema.safeParse(data);
        expect(result.success).toBe(true);
        if (result.success) {
          expect(result.data.date).toBeInstanceOf(Date);
        }
      });
    });

    describe('Null and Undefined Values', () => {
      it('should reject null values in required fields', () => {
        const data = {
          email: null,
          password: 'password123'
        };

        const result = LoginSchema.safeParse(data);
        expect(result.success).toBe(false);
      });

      it('should reject undefined values in required fields', () => {
        const data = {
          email: undefined,
          password: 'password123'
        };

        const result = LoginSchema.safeParse(data);
        expect(result.success).toBe(false);
      });

      it('should accept undefined in optional fields', () => {
        const data = {
          email: 'test@example.com',
          password: 'password123',
          role: 'student' as const,
          profile: {
            name: 'Test',
            phone: '12345',
            membershipType: undefined // Optional field
          }
        };

        const result = RegisterSchema.safeParse(data);
        expect(result.success).toBe(true);
      });
    });

    describe('Error Message Quality', () => {
      it('should provide clear error message for invalid email', () => {
        const result = LoginSchema.safeParse({
          email: 'not-an-email',
          password: 'password123'
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          const emailError = result.error.issues.find(i => i.path.includes('email'));
          expect(emailError?.message).toBeTruthy();
          expect(emailError?.message.toLowerCase()).toContain('email');
        }
      });

      it('should provide clear error message for short password', () => {
        const result = LoginSchema.safeParse({
          email: 'test@example.com',
          password: '123'
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          const passwordError = result.error.issues.find(i => i.path.includes('password'));
          expect(passwordError?.message).toBeTruthy();
        }
      });

      it('should provide clear error message for invalid date', () => {
        const result = PublishScheduleSchema.safeParse({
          professorId: 'prof123',
          date: 'not-a-date',
          startTime: '09:00',
          endTime: '10:00',
          type: 'individual' as const
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          const dateError = result.error.issues.find(i => i.path.includes('date'));
          expect(dateError?.message).toContain('Invalid date');
        }
      });
    });

    describe('Multiple Errors', () => {
      it('should collect multiple validation errors', () => {
        const result = RegisterSchema.safeParse({
          email: 'invalid',
          password: '123',
          role: 'invalid',
          profile: {
            name: 'A',
            phone: '123'
          }
        });

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.error.issues.length).toBeGreaterThanOrEqual(4);
        }
      });

      it('should report all missing required fields', () => {
        const result = RegisterSchema.safeParse({});

        expect(result.success).toBe(false);
        if (!result.success) {
          expect(result.error.issues.length).toBeGreaterThan(0);
          const paths = result.error.issues.map(i => i.path.join('.'));
          expect(paths).toContain('email');
          expect(paths).toContain('password');
          expect(paths).toContain('role');
        }
      });
    });
  });
});


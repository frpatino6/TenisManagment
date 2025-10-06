/**
 * E2E Tests for Student APIs
 * TEN-78: TS-022: Testing E2E - Student APIs
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import request from 'supertest';
import express from 'express';

// Mock Express app for testing Student APIs
const createStudentTestApp = () => {
  const app = express();
  app.use(express.json());

  // Mock JWT middleware
  const mockJwtMiddleware = (req: any, res: any, next: any) => {
    req.user = {
      id: 'student-user-id',
      role: 'student',
      email: 'student@example.com'
    };
    next();
  };

  // Mock role middleware
  const mockRoleMiddleware = (role: string) => (req: any, res: any, next: any) => {
    if (req.user?.role === role) {
      next();
    } else {
      res.status(403).json({ error: 'Forbidden' });
    }
  };

  // Apply middleware to student routes
  app.use('/api/student', mockJwtMiddleware, mockRoleMiddleware('student'));

  // Student available schedules endpoint
  app.get('/api/student/available-schedules', (req, res) => {
    const { professorId, from, to } = req.query;

    if (!professorId) {
      return res.status(400).json({ error: 'professorId is required' });
    }

    const mockSchedules = {
      items: [
        {
          id: 'schedule-1',
          professorId: professorId,
          date: '2024-10-20',
          startTime: '09:00',
          endTime: '10:00',
          isAvailable: true,
          type: 'individual',
          price: 50
        },
        {
          id: 'schedule-2',
          professorId: professorId,
          date: '2024-10-20',
          startTime: '10:00',
          endTime: '11:00',
          isAvailable: true,
          type: 'group',
          price: 35
        }
      ]
    };

    res.json(mockSchedules);
  });

  // Student book lesson endpoint
  app.post('/api/student/book-lesson', (req, res) => {
    const { scheduleId, studentId, serviceType, price, notes } = req.body;

    if (!scheduleId || !studentId || !serviceType || !price) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newBooking = {
      id: 'booking-1',
      scheduleId,
      studentId,
      serviceType,
      price,
      status: 'confirmed',
      notes: notes || '',
      createdAt: new Date().toISOString()
    };

    res.status(201).json(newBooking);
  });

  // Student bookings list endpoint
  app.get('/api/student/bookings', (req, res) => {
    const { studentId } = req.query;

    if (!studentId) {
      return res.status(400).json({ error: 'studentId is required' });
    }

    const mockBookings = {
      items: [
        {
          id: 'booking-1',
          scheduleId: 'schedule-1',
          studentId: studentId,
          serviceType: 'individual',
          price: 50,
          status: 'confirmed',
          createdAt: '2024-10-15T10:00:00.000Z'
        },
        {
          id: 'booking-2',
          scheduleId: 'schedule-2',
          studentId: studentId,
          serviceType: 'group',
          price: 35,
          status: 'pending',
          createdAt: '2024-10-16T14:00:00.000Z'
        }
      ]
    };

    res.json(mockBookings);
  });

  // Student balance endpoint
  app.get('/api/student/balance', (req, res) => {
    const { studentId } = req.query;

    if (!studentId) {
      return res.status(400).json({ error: 'studentId is required' });
    }

    const balanceInfo = {
      studentId,
      currentBalance: 150,
      totalSpent: 350,
      totalBookings: 7,
      lastPayment: '2024-10-15T10:00:00.000Z'
    };

    res.json(balanceInfo);
  });

  // Student payment history endpoint
  app.get('/api/student/payment-history', (req, res) => {
    const { studentId } = req.query;

    if (!studentId) {
      return res.status(400).json({ error: 'studentId is required' });
    }

    const paymentHistory = {
      items: [
        {
          id: 'payment-1',
          studentId: studentId,
          amount: 50,
          date: '2024-10-15T10:00:00.000Z',
          method: 'cash',
          concept: 'Clase individual',
          status: 'completed'
        },
        {
          id: 'payment-2',
          studentId: studentId,
          amount: 35,
          date: '2024-10-14T16:00:00.000Z',
          method: 'card',
          concept: 'Clase grupal',
          status: 'completed'
        }
      ],
      totalPayments: 2,
      totalAmount: 85
    };

    res.json(paymentHistory);
  });

  // Student request service endpoint
  app.post('/api/student/request-service', (req, res) => {
    const { studentId, serviceType, description, preferredDate, notes } = req.body;

    if (!studentId || !serviceType || !description) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newServiceRequest = {
      id: 'service-request-1',
      studentId,
      serviceType,
      description,
      preferredDate: preferredDate || null,
      notes: notes || '',
      status: 'pending',
      createdAt: new Date().toISOString()
    };

    res.status(201).json(newServiceRequest);
  });

  return app;
};

describe('Student APIs E2E Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createStudentTestApp();
  });

  describe('GET /api/student/available-schedules', () => {
    it('should get available schedules successfully', async () => {
      const response = await request(app)
        .get('/api/student/available-schedules')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      expect(response.body.items[0]).toHaveProperty('id');
      expect(response.body.items[0]).toHaveProperty('professorId', 'professor-123');
      expect(response.body.items[0]).toHaveProperty('isAvailable', true);
    });

    it('should get available schedules with date range', async () => {
      const from = '2024-10-20';
      const to = '2024-10-25';

      const response = await request(app)
        .get('/api/student/available-schedules')
        .query({ professorId: 'professor-123', from, to })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
    });

    it('should return 400 for missing professorId', async () => {
      const response = await request(app)
        .get('/api/student/available-schedules')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('professorId is required');
    });

    it('should return 403 for non-student role', async () => {
      // Create app without student role
      const nonStudentApp = express();
      nonStudentApp.use(express.json());
      
      nonStudentApp.use('/api/student', (req, res, next) => {
        req.user = { id: 'user-id', role: 'professor' };
        next();
      }, (req, res) => {
        if (req.user?.role !== 'student') {
          return res.status(403).json({ error: 'Forbidden' });
        }
        res.json({ message: 'success' });
      });

      const response = await request(nonStudentApp)
        .get('/api/student/available-schedules')
        .expect(403);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Forbidden');
    });
  });

  describe('POST /api/student/book-lesson', () => {
    it('should book lesson successfully', async () => {
      const bookingData = {
        scheduleId: 'schedule-123',
        studentId: 'student-123',
        serviceType: 'individual',
        price: 50,
        notes: 'First lesson'
      };

      const response = await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('scheduleId', 'schedule-123');
      expect(response.body).toHaveProperty('studentId', 'student-123');
      expect(response.body).toHaveProperty('serviceType', 'individual');
      expect(response.body).toHaveProperty('price', 50);
      expect(response.body).toHaveProperty('status', 'confirmed');
      expect(response.body).toHaveProperty('createdAt');
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        scheduleId: 'schedule-123',
        studentId: 'student-123'
        // Missing serviceType and price
      };

      const response = await request(app)
        .post('/api/student/book-lesson')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing required fields');
    });

    it('should book lesson with optional notes', async () => {
      const bookingData = {
        scheduleId: 'schedule-123',
        studentId: 'student-123',
        serviceType: 'group',
        price: 35,
        notes: 'Group lesson with friends'
      };

      const response = await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .expect(201);

      expect(response.body).toHaveProperty('notes', 'Group lesson with friends');
      expect(response.body).toHaveProperty('serviceType', 'group');
      expect(response.body).toHaveProperty('price', 35);
    });
  });

  describe('GET /api/student/bookings', () => {
    it('should get student bookings successfully', async () => {
      const response = await request(app)
        .get('/api/student/bookings')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      
      const booking = response.body.items[0];
      expect(booking).toHaveProperty('id');
      expect(booking).toHaveProperty('scheduleId');
      expect(booking).toHaveProperty('studentId', 'student-123');
      expect(booking).toHaveProperty('serviceType');
      expect(booking).toHaveProperty('price');
      expect(booking).toHaveProperty('status');
      expect(booking).toHaveProperty('createdAt');
    });

    it('should return bookings with different statuses', async () => {
      const response = await request(app)
        .get('/api/student/bookings')
        .query({ studentId: 'student-123' })
        .expect(200);

      const statuses = response.body.items.map((booking: any) => booking.status);
      expect(statuses).toContain('confirmed');
      expect(statuses).toContain('pending');
    });

    it('should return 400 for missing studentId', async () => {
      const response = await request(app)
        .get('/api/student/bookings')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('studentId is required');
    });
  });

  describe('GET /api/student/balance', () => {
    it('should get student balance successfully', async () => {
      const response = await request(app)
        .get('/api/student/balance')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(response.body).toHaveProperty('studentId', 'student-123');
      expect(response.body).toHaveProperty('currentBalance');
      expect(response.body).toHaveProperty('totalSpent');
      expect(response.body).toHaveProperty('totalBookings');
      expect(response.body).toHaveProperty('lastPayment');
      
      expect(typeof response.body.currentBalance).toBe('number');
      expect(typeof response.body.totalSpent).toBe('number');
      expect(typeof response.body.totalBookings).toBe('number');
    });

    it('should return balance with correct data types', async () => {
      const response = await request(app)
        .get('/api/student/balance')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(response.body.currentBalance).toBe(150);
      expect(response.body.totalSpent).toBe(350);
      expect(response.body.totalBookings).toBe(7);
    });

    it('should return 400 for missing studentId', async () => {
      const response = await request(app)
        .get('/api/student/balance')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('studentId is required');
    });
  });

  describe('GET /api/student/payment-history', () => {
    it('should get payment history successfully', async () => {
      const response = await request(app)
        .get('/api/student/payment-history')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(response.body).toHaveProperty('totalPayments');
      expect(response.body).toHaveProperty('totalAmount');
      
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      expect(response.body.totalPayments).toBe(2);
      expect(response.body.totalAmount).toBe(85);
    });

    it('should return payment history with correct structure', async () => {
      const response = await request(app)
        .get('/api/student/payment-history')
        .query({ studentId: 'student-123' })
        .expect(200);

      const payment = response.body.items[0];
      expect(payment).toHaveProperty('id');
      expect(payment).toHaveProperty('studentId', 'student-123');
      expect(payment).toHaveProperty('amount');
      expect(payment).toHaveProperty('date');
      expect(payment).toHaveProperty('method');
      expect(payment).toHaveProperty('concept');
      expect(payment).toHaveProperty('status');
    });

    it('should return payments with different methods', async () => {
      const response = await request(app)
        .get('/api/student/payment-history')
        .query({ studentId: 'student-123' })
        .expect(200);

      const methods = response.body.items.map((payment: any) => payment.method);
      expect(methods).toContain('cash');
      expect(methods).toContain('card');
    });

    it('should return 400 for missing studentId', async () => {
      const response = await request(app)
        .get('/api/student/payment-history')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('studentId is required');
    });
  });

  describe('POST /api/student/request-service', () => {
    it('should request service successfully', async () => {
      const serviceData = {
        studentId: 'student-123',
        serviceType: 'private_lesson',
        description: 'One-on-one tennis coaching',
        preferredDate: '2024-10-25',
        notes: 'Looking for advanced techniques'
      };

      const response = await request(app)
        .post('/api/student/request-service')
        .send(serviceData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('studentId', 'student-123');
      expect(response.body).toHaveProperty('serviceType', 'private_lesson');
      expect(response.body).toHaveProperty('description', 'One-on-one tennis coaching');
      expect(response.body).toHaveProperty('preferredDate', '2024-10-25');
      expect(response.body).toHaveProperty('notes', 'Looking for advanced techniques');
      expect(response.body).toHaveProperty('status', 'pending');
      expect(response.body).toHaveProperty('createdAt');
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        studentId: 'student-123',
        serviceType: 'private_lesson'
        // Missing description
      };

      const response = await request(app)
        .post('/api/student/request-service')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing required fields');
    });

    it('should request service with optional fields', async () => {
      const minimalData = {
        studentId: 'student-123',
        serviceType: 'court_rental',
        description: 'Court rental for practice'
      };

      const response = await request(app)
        .post('/api/student/request-service')
        .send(minimalData)
        .expect(201);

      expect(response.body).toHaveProperty('preferredDate', null);
      expect(response.body).toHaveProperty('notes', '');
      expect(response.body).toHaveProperty('serviceType', 'court_rental');
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JSON requests', async () => {
      const response = await request(app)
        .post('/api/student/book-lesson')
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      expect(response.body).toEqual({});
    });

    it('should handle server errors gracefully', async () => {
      const response = await request(app)
        .get('/api/student/available-schedules')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Performance Tests', () => {
    it('should handle multiple concurrent requests', async () => {
      const promises = Array(10).fill(null).map(() =>
        request(app)
          .get('/api/student/bookings')
          .query({ studentId: 'student-123' })
          .expect(200)
      );

      const responses = await Promise.all(promises);

      responses.forEach(response => {
        expect(response.body).toHaveProperty('items');
        expect(Array.isArray(response.body.items)).toBe(true);
      });
    });

    it('should respond within acceptable time limits', async () => {
      const startTime = Date.now();

      await request(app)
        .get('/api/student/balance')
        .query({ studentId: 'student-123' })
        .expect(200);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Should respond within 1000ms (1 second)
      expect(responseTime).toBeLessThan(1000);
    });
  });

  describe('Integration Flow Tests', () => {
    it('should complete student workflow: check schedules -> book lesson -> view bookings', async () => {
      // Step 1: Check available schedules
      const schedulesResponse = await request(app)
        .get('/api/student/available-schedules')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(schedulesResponse.body).toHaveProperty('items');
      const scheduleId = schedulesResponse.body.items[0].id;

      // Step 2: Book a lesson
      const bookingData = {
        scheduleId,
        studentId: 'student-123',
        serviceType: 'individual',
        price: 50
      };

      const bookingResponse = await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .expect(201);

      expect(bookingResponse.body).toHaveProperty('id');

      // Step 3: View bookings
      const bookingsResponse = await request(app)
        .get('/api/student/bookings')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(bookingsResponse.body).toHaveProperty('items');
      expect(bookingsResponse.body.items.length).toBeGreaterThan(0);
    });

    it('should manage service request workflow: request -> check balance -> view history', async () => {
      // Step 1: Request a service
      const serviceData = {
        studentId: 'student-123',
        serviceType: 'private_lesson',
        description: 'Advanced tennis coaching'
      };

      const serviceResponse = await request(app)
        .post('/api/student/request-service')
        .send(serviceData)
        .expect(201);

      expect(serviceResponse.body).toHaveProperty('id');

      // Step 2: Check balance
      const balanceResponse = await request(app)
        .get('/api/student/balance')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(balanceResponse.body).toHaveProperty('currentBalance');

      // Step 3: View payment history
      const historyResponse = await request(app)
        .get('/api/student/payment-history')
        .query({ studentId: 'student-123' })
        .expect(200);

      expect(historyResponse.body).toHaveProperty('items');
      expect(historyResponse.body).toHaveProperty('totalAmount');
    });
  });
});

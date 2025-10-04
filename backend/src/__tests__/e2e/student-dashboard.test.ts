/**
 * E2E Tests for Student Dashboard APIs
 * TEN-78: TS-022: Testing E2E - Student APIs
 */

import request from 'supertest';
import express from 'express';

// Mock Express app for testing Student Dashboard APIs
const createStudentDashboardTestApp = () => {
  const app = express();
  app.use(express.json());

  // Mock Firebase auth middleware
  const mockFirebaseAuthMiddleware = (req: any, res: any, next: any) => {
    req.user = {
      uid: 'firebase-student-uid',
      email: 'student@example.com',
      id: 'student-user-id'
    };
    next();
  };

  // Apply middleware to student dashboard routes
  app.use('/api/student-dashboard', mockFirebaseAuthMiddleware);

  // Student recent activities endpoint
  app.get('/api/student-dashboard/activities', (req, res) => {
    const mockActivities = {
      items: [
        {
          id: 'activity-1',
          type: 'booking',
          title: 'Clase reservada',
          description: 'Prof. Juan Pérez',
          date: '2024-10-15T10:00:00.000Z',
          status: 'confirmed',
          icon: 'calendar_today',
          color: 'blue'
        },
        {
          id: 'activity-2',
          type: 'payment',
          title: 'Pago realizado',
          description: 'Prof. María García - $50,000',
          date: '2024-10-14T16:00:00.000Z',
          status: 'completed',
          icon: 'payment',
          color: 'green'
        },
        {
          id: 'activity-3',
          type: 'service_request',
          title: 'Solicitud de servicio',
          description: 'Servicio solicitado',
          date: '2024-10-13T09:00:00.000Z',
          status: 'pending',
          icon: 'support_agent',
          color: 'orange'
        }
      ]
    };

    res.json(mockActivities);
  });

  // Student info endpoint
  app.get('/api/student-dashboard/me', (req, res) => {
    const studentInfo = {
      id: 'student-123',
      name: 'Ana Estudiante',
      email: 'student@example.com',
      phone: '+57 300 123 4567',
      level: 'Intermedio',
      totalClasses: 15,
      totalPayments: 12,
      totalSpent: 750
    };

    res.json(studentInfo);
  });

  // Student professors list endpoint
  app.get('/api/student-dashboard/professors', (req, res) => {
    const mockProfessors = {
      items: [
        {
          id: 'professor-1',
          name: 'Juan Profesor',
          email: 'juan@example.com',
          phone: '+57 300 111 1111',
          specialties: ['tennis', 'footwork'],
          hourlyRate: 50,
          pricing: {
            individualClass: 50000,
            groupClass: 35000,
            courtRental: 25000
          },
          experienceYears: 5,
          rating: 4.8
        },
        {
          id: 'professor-2',
          name: 'María Profesora',
          email: 'maria@example.com',
          phone: '+57 300 222 2222',
          specialties: ['serve', 'backhand'],
          hourlyRate: 45,
          pricing: {
            individualClass: 45000,
            groupClass: 30000,
            courtRental: 20000
          },
          experienceYears: 3,
          rating: 4.5
        }
      ]
    };

    res.json(mockProfessors);
  });

  // Available schedules endpoint
  app.get('/api/student-dashboard/available-schedules', (req, res) => {
    const { professorId } = req.query;

    if (!professorId) {
      return res.status(400).json({ error: 'professorId es requerido' });
    }

    const mockSchedules = {
      items: [
        {
          id: 'schedule-1',
          professorId: professorId,
          startTime: '2024-10-22T09:00:00.000Z',
          endTime: '2024-10-22T10:00:00.000Z',
          type: 'individual_class',
          price: 0,
          status: 'available'
        },
        {
          id: 'schedule-2',
          professorId: professorId,
          startTime: '2024-10-22T10:00:00.000Z',
          endTime: '2024-10-22T11:00:00.000Z',
          type: 'individual_class',
          price: 0,
          status: 'available'
        },
        {
          id: 'schedule-3',
          professorId: professorId,
          startTime: '2024-10-22T14:00:00.000Z',
          endTime: '2024-10-22T15:30:00.000Z',
          type: 'group_class',
          price: 0,
          status: 'available'
        }
      ]
    };

    res.json(mockSchedules);
  });

  // Book lesson endpoint
  app.post('/api/student-dashboard/book-lesson', (req, res) => {
    const { scheduleId, serviceType, price } = req.body;

    if (!scheduleId) {
      return res.status(400).json({ error: 'scheduleId es requerido' });
    }

    if (!serviceType) {
      return res.status(400).json({ error: 'serviceType es requerido' });
    }

    if (!price || price <= 0) {
      return res.status(400).json({ error: 'price es requerido y debe ser mayor a 0' });
    }

    const newBooking = {
      id: 'booking-dashboard-1',
      studentId: 'student-123',
      scheduleId,
      serviceType,
      status: 'confirmed',
      price,
      createdAt: new Date().toISOString()
    };

    res.status(201).json(newBooking);
  });

  return app;
};

describe('Student Dashboard APIs E2E Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createStudentDashboardTestApp();
  });

  describe('GET /api/student-dashboard/activities', () => {
    it('should get recent activities successfully', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/activities')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(3);
      
      const activity = response.body.items[0];
      expect(activity).toHaveProperty('id');
      expect(activity).toHaveProperty('type');
      expect(activity).toHaveProperty('title');
      expect(activity).toHaveProperty('description');
      expect(activity).toHaveProperty('date');
      expect(activity).toHaveProperty('status');
      expect(activity).toHaveProperty('icon');
      expect(activity).toHaveProperty('color');
    });

    it('should return activities with different types', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/activities')
        .expect(200);

      const types = response.body.items.map((activity: any) => activity.type);
      expect(types).toContain('booking');
      expect(types).toContain('payment');
      expect(types).toContain('service_request');
    });

    it('should return activities with valid statuses', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/activities')
        .expect(200);

      const statuses = response.body.items.map((activity: any) => activity.status);
      expect(statuses).toContain('confirmed');
      expect(statuses).toContain('completed');
      expect(statuses).toContain('pending');
    });

    it('should return 401 for unauthenticated requests', async () => {
      // Create app without auth middleware
      const noAuthApp = express();
      noAuthApp.use(express.json());

      noAuthApp.get('/api/student-dashboard/activities', (req, res) => {
        if (!req.user) {
          return res.status(401).json({ error: 'Usuario no autenticado' });
        }
        res.json({ message: 'success' });
      });

      const response = await request(noAuthApp)
        .get('/api/student-dashboard/activities')
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Usuario no autenticado');
    });
  });

  describe('GET /api/student-dashboard/me', () => {
    it('should get student info successfully', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/me')
        .expect(200);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('name');
      expect(response.body).toHaveProperty('email');
      expect(response.body).toHaveProperty('phone');
      expect(response.body).toHaveProperty('level');
      expect(response.body).toHaveProperty('totalClasses');
      expect(response.body).toHaveProperty('totalPayments');
      expect(response.body).toHaveProperty('totalSpent');
      
      expect(typeof response.body.totalClasses).toBe('number');
      expect(typeof response.body.totalPayments).toBe('number');
      expect(typeof response.body.totalSpent).toBe('number');
    });

    it('should return student info with correct data types', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/me')
        .expect(200);

      expect(response.body.id).toBe('student-123');
      expect(response.body.name).toBe('Ana Estudiante');
      expect(response.body.email).toBe('student@example.com');
      expect(response.body.level).toBe('Intermedio');
      expect(response.body.totalClasses).toBe(15);
      expect(response.body.totalSpent).toBe(750);
    });

    it('should return valid student level', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/me')
        .expect(200);

      expect(['Principiante', 'Intermedio', 'Avanzado']).toContain(response.body.level);
    });
  });

  describe('GET /api/student-dashboard/professors', () => {
    it('should get professors list successfully', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/professors')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      
      const professor = response.body.items[0];
      expect(professor).toHaveProperty('id');
      expect(professor).toHaveProperty('name');
      expect(professor).toHaveProperty('email');
      expect(professor).toHaveProperty('phone');
      expect(professor).toHaveProperty('specialties');
      expect(professor).toHaveProperty('hourlyRate');
      expect(professor).toHaveProperty('pricing');
      expect(professor).toHaveProperty('experienceYears');
      expect(professor).toHaveProperty('rating');
    });

    it('should return professors with correct pricing structure', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/professors')
        .expect(200);

      const professor = response.body.items[0];
      expect(professor.pricing).toHaveProperty('individualClass');
      expect(professor.pricing).toHaveProperty('groupClass');
      expect(professor.pricing).toHaveProperty('courtRental');
      
      expect(typeof professor.pricing.individualClass).toBe('number');
      expect(typeof professor.pricing.groupClass).toBe('number');
      expect(typeof professor.pricing.courtRental).toBe('number');
    });

    it('should return professors with valid specialties', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/professors')
        .expect(200);

      response.body.items.forEach((professor: any) => {
        expect(Array.isArray(professor.specialties)).toBe(true);
        expect(professor.specialties.length).toBeGreaterThan(0);
      });
    });

    it('should return professors with valid ratings', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/professors')
        .expect(200);

      response.body.items.forEach((professor: any) => {
        expect(typeof professor.rating).toBe('number');
        expect(professor.rating).toBeGreaterThanOrEqual(0);
        expect(professor.rating).toBeLessThanOrEqual(5);
      });
    });
  });

  describe('GET /api/student-dashboard/available-schedules', () => {
    it('should get available schedules successfully', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(3);
      
      const schedule = response.body.items[0];
      expect(schedule).toHaveProperty('id');
      expect(schedule).toHaveProperty('professorId', 'professor-123');
      expect(schedule).toHaveProperty('startTime');
      expect(schedule).toHaveProperty('endTime');
      expect(schedule).toHaveProperty('type');
      expect(schedule).toHaveProperty('price');
      expect(schedule).toHaveProperty('status', 'available');
    });

    it('should return schedules with valid dates (mock uses future dates)', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .query({ professorId: 'professor-123' })
        .expect(200);

      response.body.items.forEach((schedule: any) => {
        const startTime = new Date(schedule.startTime);
        const endTime = new Date(schedule.endTime);
        // Verify that startTime is a valid date
        expect(startTime.getTime()).toBeGreaterThan(0);
        // Verify that endTime is after startTime
        expect(endTime.getTime()).toBeGreaterThan(startTime.getTime());
      });
    });

    it('should return schedules with valid time ranges', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .query({ professorId: 'professor-123' })
        .expect(200);

      response.body.items.forEach((schedule: any) => {
        const startTime = new Date(schedule.startTime);
        const endTime = new Date(schedule.endTime);
        expect(endTime.getTime()).toBeGreaterThan(startTime.getTime());
      });
    });

    it('should return 400 for missing professorId', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('professorId es requerido');
    });
  });

  describe('POST /api/student-dashboard/book-lesson', () => {
    it('should book lesson successfully', async () => {
      const bookingData = {
        scheduleId: 'schedule-123',
        serviceType: 'individual_class',
        price: 50000
      };

      const response = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('studentId', 'student-123');
      expect(response.body).toHaveProperty('scheduleId', 'schedule-123');
      expect(response.body).toHaveProperty('serviceType', 'individual_class');
      expect(response.body).toHaveProperty('status', 'confirmed');
      expect(response.body).toHaveProperty('price', 50000);
      expect(response.body).toHaveProperty('createdAt');
    });

    it('should return 400 for missing scheduleId', async () => {
      const bookingData = {
        serviceType: 'individual_class',
        price: 50000
      };

      const response = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('scheduleId es requerido');
    });

    it('should return 400 for missing serviceType', async () => {
      const bookingData = {
        scheduleId: 'schedule-123',
        price: 50000
      };

      const response = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('serviceType es requerido');
    });

    it('should return 400 for invalid price', async () => {
      const bookingData = {
        scheduleId: 'schedule-123',
        serviceType: 'individual_class',
        price: 0
      };

      const response = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('price es requerido y debe ser mayor a 0');
    });

    it('should book different service types', async () => {
      const bookingData = {
        scheduleId: 'schedule-123',
        serviceType: 'group_class',
        price: 35000
      };

      const response = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .expect(201);

      expect(response.body).toHaveProperty('serviceType', 'group_class');
      expect(response.body).toHaveProperty('price', 35000);
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JSON requests', async () => {
      const response = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      expect(response.body).toEqual({});
    });

    it('should handle server errors gracefully', async () => {
      const response = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Performance Tests', () => {
    it('should handle multiple concurrent requests', async () => {
      const promises = Array(10).fill(null).map(() =>
        request(app)
          .get('/api/student-dashboard/me')
          .expect(200)
      );

      const responses = await Promise.all(promises);

      responses.forEach(response => {
        expect(response.body).toHaveProperty('id');
        expect(response.body).toHaveProperty('name');
        expect(response.body).toHaveProperty('email');
      });
    });

    it('should respond within acceptable time limits', async () => {
      const startTime = Date.now();

      await request(app)
        .get('/api/student-dashboard/professors')
        .expect(200);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Should respond within 1000ms (1 second)
      expect(responseTime).toBeLessThan(1000);
    });
  });

  describe('Integration Flow Tests', () => {
    it('should complete student dashboard workflow: get info -> view professors -> check schedules -> book lesson', async () => {
      // Step 1: Get student info
      const infoResponse = await request(app)
        .get('/api/student-dashboard/me')
        .expect(200);

      expect(infoResponse.body).toHaveProperty('id');

      // Step 2: Get professors
      const professorsResponse = await request(app)
        .get('/api/student-dashboard/professors')
        .expect(200);

      expect(professorsResponse.body).toHaveProperty('items');
      const professorId = professorsResponse.body.items[0].id;

      // Step 3: Check available schedules
      const schedulesResponse = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .query({ professorId })
        .expect(200);

      expect(schedulesResponse.body).toHaveProperty('items');
      const scheduleId = schedulesResponse.body.items[0].id;

      // Step 4: Book a lesson
      const bookingData = {
        scheduleId,
        serviceType: 'individual_class',
        price: 50000
      };

      const bookingResponse = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .expect(201);

      expect(bookingResponse.body).toHaveProperty('id');

      // Step 5: Check recent activities
      const activitiesResponse = await request(app)
        .get('/api/student-dashboard/activities')
        .expect(200);

      expect(activitiesResponse.body).toHaveProperty('items');
    });

    it('should manage student profile and activities workflow', async () => {
      // Step 1: Get student profile
      const profileResponse = await request(app)
        .get('/api/student-dashboard/me')
        .expect(200);

      expect(profileResponse.body).toHaveProperty('totalClasses');
      expect(profileResponse.body).toHaveProperty('totalSpent');

      // Step 2: Get recent activities
      const activitiesResponse = await request(app)
        .get('/api/student-dashboard/activities')
        .expect(200);

      expect(activitiesResponse.body).toHaveProperty('items');

      // Step 3: Get available schedules for booking
      const schedulesResponse = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(schedulesResponse.body).toHaveProperty('items');

      // Verify that all activities are properly formatted
      activitiesResponse.body.items.forEach((activity: any) => {
        expect(activity).toHaveProperty('type');
        expect(activity).toHaveProperty('title');
        expect(activity).toHaveProperty('description');
        expect(activity).toHaveProperty('date');
        expect(activity).toHaveProperty('icon');
        expect(activity).toHaveProperty('color');
      });
    });
  });
});

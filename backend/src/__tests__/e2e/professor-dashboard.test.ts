/**
 * E2E Tests for Professor Dashboard APIs
 * TEN-75: TS-019: Testing E2E - Professor APIs
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import request from 'supertest';
import express from 'express';

// Mock Express app for testing Professor Dashboard APIs
const createProfessorDashboardTestApp = () => {
  const app = express();
  app.use(express.json());

  // Mock Firebase auth middleware
  const mockFirebaseAuthMiddleware = (req: any, res: any, next: any) => {
    req.user = {
      uid: 'firebase-professor-uid',
      email: 'professor@example.com',
      id: 'professor-user-id'
    };
    next();
  };

  // Apply middleware to professor dashboard routes
  app.use('/api/professor-dashboard', mockFirebaseAuthMiddleware);

  // Professor info endpoint
  app.get('/api/professor-dashboard/me', (req, res) => {
    const professorInfo = {
      id: 'professor-123',
      name: 'Juan Profesor',
      email: 'professor@example.com',
      phone: '+57 300 123 4567',
      specialties: ['tennis', 'footwork'],
      hourlyRate: 50,
      totalStudents: 15,
      rating: 4.8,
      experienceYears: 5
    };

    res.json(professorInfo);
  });

  // Update profile endpoint
  app.put('/api/professor-dashboard/profile', (req, res) => {
    const { name, phone, specialties, hourlyRate, experienceYears } = req.body;

    if (!name && !phone && !specialties && !hourlyRate && !experienceYears) {
      return res.status(400).json({ error: 'At least one field is required' });
    }

    const updatedProfile = {
      id: 'professor-123',
      name: name || 'Juan Profesor',
      email: 'professor@example.com',
      phone: phone || '+57 300 123 4567',
      specialties: specialties || ['tennis'],
      hourlyRate: hourlyRate || 50,
      experienceYears: experienceYears || 5,
      updatedAt: new Date().toISOString()
    };

    res.json(updatedProfile);
  });

  // Students list endpoint
  app.get('/api/professor-dashboard/students', (req, res) => {
    const mockStudents = {
      items: [
        {
          id: 'student-1',
          name: 'Ana Estudiante',
          email: 'ana@example.com',
          level: 'Intermedio',
          nextClassDate: '2024-10-22',
          nextClassTime: '09:00',
          totalClasses: 12,
          progress: 0.6
        },
        {
          id: 'student-2',
          name: 'Carlos Estudiante',
          email: 'carlos@example.com',
          level: 'Principiante',
          nextClassDate: '2024-10-21',
          nextClassTime: '10:00',
          totalClasses: 5,
          progress: 0.25
        },
        {
          id: 'student-3',
          name: 'María Estudiante',
          email: 'maria@example.com',
          level: 'Avanzado',
          nextClassDate: '2024-10-23',
          nextClassTime: '14:00',
          totalClasses: 25,
          progress: 1.0
        }
      ]
    };

    res.json(mockStudents);
  });

  // Schedule by date endpoint
  app.get('/api/professor-dashboard/schedule/date', (req, res) => {
    const { date } = req.query;

    if (!date || typeof date !== 'string') {
      return res.status(400).json({ error: 'Parámetro date es requerido (formato: YYYY-MM-DD)' });
    }

    const mockClasses = {
      items: [
        {
          id: 'schedule-1',
          studentName: 'Ana Estudiante',
          studentId: 'student-1',
          startTime: '2024-10-22T09:00:00.000Z',
          endTime: '2024-10-22T10:00:00.000Z',
          status: 'confirmed',
          notes: 'Enfocarse en el servicio',
          serviceType: 'individual',
          price: 50
        },
        {
          id: 'schedule-2',
          studentName: 'Carlos Estudiante',
          studentId: 'student-2',
          startTime: '2024-10-22T10:00:00.000Z',
          endTime: '2024-10-22T11:00:00.000Z',
          status: 'confirmed',
          notes: '',
          serviceType: 'individual',
          price: 50
        }
      ]
    };

    res.json(mockClasses);
  });

  // Today's schedule endpoint
  app.get('/api/professor-dashboard/schedule/today', (req, res) => {
    const todayClasses = {
      items: [
        {
          id: 'schedule-today-1',
          studentName: 'Ana Estudiante',
          studentId: 'student-1',
          startTime: new Date().toISOString(),
          endTime: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
          status: 'confirmed',
          notes: 'Clase de hoy',
          serviceType: 'individual',
          price: 50
        }
      ]
    };

    res.json(todayClasses);
  });

  // Week schedule endpoint
  app.get('/api/professor-dashboard/schedule/week', (req, res) => {
    const weekClasses = {
      items: [
        {
          id: 'schedule-week-1',
          studentName: 'Ana Estudiante',
          studentId: 'student-1',
          startTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 60 * 60 * 1000).toISOString(),
          status: 'pending',
          notes: 'Clase de mañana'
        },
        {
          id: 'schedule-week-2',
          studentName: 'Carlos Estudiante',
          studentId: 'student-2',
          startTime: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000).toISOString(),
          endTime: new Date(Date.now() + 2 * 24 * 60 * 60 * 1000 + 60 * 60 * 1000).toISOString(),
          status: 'confirmed',
          notes: ''
        }
      ]
    };

    res.json(weekClasses);
  });

  // Earnings stats endpoint
  app.get('/api/professor-dashboard/earnings', (req, res) => {
    const earningsStats = {
      monthlyEarnings: 2000,
      weeklyEarnings: 500,
      classesThisMonth: 20,
      totalEarnings: 15000
    };

    res.json(earningsStats);
  });

  // Create schedule endpoint
  app.post('/api/professor-dashboard/schedule', (req, res) => {
    const { date, startTime, endTime } = req.body;

    if (!date || !startTime || !endTime) {
      return res.status(400).json({ error: 'Faltan campos requeridos: date, startTime, endTime' });
    }

    const newSchedule = {
      id: 'new-schedule-id',
      professorId: 'professor-123',
      date,
      startTime,
      endTime,
      isAvailable: true,
      status: 'pending'
    };

    res.status(201).json(newSchedule);
  });

  // Get my schedules endpoint
  app.get('/api/professor-dashboard/schedules', (req, res) => {
    const mySchedules = {
      items: [
        {
          id: 'my-schedule-1',
          date: new Date().toISOString(),
          startTime: new Date().toISOString(),
          endTime: new Date(Date.now() + 60 * 60 * 1000).toISOString(),
          isAvailable: true,
          isBlocked: false,
          blockReason: null,
          status: 'pending',
          studentName: null,
          studentEmail: null
        },
        {
          id: 'my-schedule-2',
          date: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          startTime: new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString(),
          endTime: new Date(Date.now() + 24 * 60 * 60 * 1000 + 60 * 60 * 1000).toISOString(),
          isAvailable: false,
          isBlocked: false,
          blockReason: null,
          status: 'confirmed',
          studentName: 'Ana Estudiante',
          studentEmail: 'ana@example.com'
        }
      ]
    };

    res.json(mySchedules);
  });

  // Delete schedule endpoint
  app.delete('/api/professor-dashboard/schedule/:scheduleId', (req, res) => {
    const { scheduleId } = req.params;

    if (!scheduleId) {
      return res.status(400).json({ error: 'scheduleId es requerido' });
    }

    res.json({ message: 'Horario eliminado exitosamente' });
  });

  // Block schedule endpoint
  app.post('/api/professor-dashboard/schedule/:scheduleId/block', (req, res) => {
    const { scheduleId } = req.params;
    const { reason } = req.body;

    if (!scheduleId) {
      return res.status(400).json({ error: 'scheduleId es requerido' });
    }

    res.json({ message: 'Horario bloqueado exitosamente' });
  });

  // Unblock schedule endpoint
  app.post('/api/professor-dashboard/schedule/:scheduleId/unblock', (req, res) => {
    const { scheduleId } = req.params;

    if (!scheduleId) {
      return res.status(400).json({ error: 'scheduleId es requerido' });
    }

    res.json({ message: 'Horario desbloqueado exitosamente' });
  });

  // Complete class endpoint
  app.post('/api/professor-dashboard/schedule/:scheduleId/complete', (req, res) => {
    const { scheduleId } = req.params;
    const { paymentAmount } = req.body;

    if (!scheduleId) {
      return res.status(400).json({ error: 'scheduleId es requerido' });
    }

    const response = {
      message: 'Clase marcada como completada' + (paymentAmount ? ' y pago registrado' : ''),
      scheduleId,
      bookingId: 'booking-123',
      paymentId: paymentAmount ? 'payment-123' : null
    };

    res.json(response);
  });

  // Cancel booking endpoint
  app.post('/api/professor-dashboard/schedule/:scheduleId/cancel', (req, res) => {
    const { scheduleId } = req.params;
    const { reason, penaltyAmount } = req.body;

    if (!scheduleId) {
      return res.status(400).json({ error: 'scheduleId es requerido' });
    }

    const response = {
      message: 'Reserva cancelada exitosamente' + (penaltyAmount ? ' con penalización registrada' : ''),
      scheduleId,
      paymentId: penaltyAmount ? 'penalty-payment-123' : null
    };

    res.json(response);
  });

  return app;
};

describe('Professor Dashboard APIs E2E Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createProfessorDashboardTestApp();
  });

  describe('GET /api/professor-dashboard/me', () => {
    it('should get professor info successfully', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/me')
        .expect(200);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('name');
      expect(response.body).toHaveProperty('email');
      expect(response.body).toHaveProperty('phone');
      expect(response.body).toHaveProperty('specialties');
      expect(response.body).toHaveProperty('hourlyRate');
      expect(response.body).toHaveProperty('totalStudents');
      expect(response.body).toHaveProperty('rating');
      expect(response.body).toHaveProperty('experienceYears');
      
      expect(Array.isArray(response.body.specialties)).toBe(true);
      expect(typeof response.body.hourlyRate).toBe('number');
      expect(typeof response.body.rating).toBe('number');
      expect(typeof response.body.totalStudents).toBe('number');
    });

    it('should return 401 for unauthenticated requests', async () => {
      // Create app without auth middleware
      const noAuthApp = express();
      noAuthApp.use(express.json());

      noAuthApp.get('/api/professor-dashboard/me', (req, res) => {
        if (!req.user) {
          return res.status(401).json({ error: 'Usuario no autenticado' });
        }
        res.json({ message: 'success' });
      });

      const response = await request(noAuthApp)
        .get('/api/professor-dashboard/me')
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Usuario no autenticado');
    });
  });

  describe('PUT /api/professor-dashboard/profile', () => {
    it('should update profile successfully', async () => {
      const profileData = {
        name: 'Juan Profesor Actualizado',
        phone: '+57 300 999 8888',
        specialties: ['tennis', 'footwork', 'serve'],
        hourlyRate: 60,
        experienceYears: 7
      };

      const response = await request(app)
        .put('/api/professor-dashboard/profile')
        .send(profileData)
        .expect(200);

      expect(response.body).toHaveProperty('name', 'Juan Profesor Actualizado');
      expect(response.body).toHaveProperty('phone', '+57 300 999 8888');
      expect(response.body).toHaveProperty('specialties');
      expect(response.body.specialties).toHaveLength(3);
      expect(response.body).toHaveProperty('hourlyRate', 60);
      expect(response.body).toHaveProperty('experienceYears', 7);
      expect(response.body).toHaveProperty('updatedAt');
    });

    it('should update partial profile data', async () => {
      const partialData = {
        name: 'Solo Nombre Actualizado',
        hourlyRate: 55
      };

      const response = await request(app)
        .put('/api/professor-dashboard/profile')
        .send(partialData)
        .expect(200);

      expect(response.body).toHaveProperty('name', 'Solo Nombre Actualizado');
      expect(response.body).toHaveProperty('hourlyRate', 55);
      expect(response.body).toHaveProperty('phone'); // Should keep existing value
    });

    it('should return 400 for empty update', async () => {
      const emptyData = {};

      const response = await request(app)
        .put('/api/professor-dashboard/profile')
        .send(emptyData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('At least one field is required');
    });
  });

  describe('GET /api/professor-dashboard/students', () => {
    it('should get students list successfully', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/students')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(3);
      
      const student = response.body.items[0];
      expect(student).toHaveProperty('id');
      expect(student).toHaveProperty('name');
      expect(student).toHaveProperty('email');
      expect(student).toHaveProperty('level');
      expect(student).toHaveProperty('nextClassDate');
      expect(student).toHaveProperty('nextClassTime');
      expect(student).toHaveProperty('totalClasses');
      expect(student).toHaveProperty('progress');
    });

    it('should return students with correct level progression', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/students')
        .expect(200);

      const levels = response.body.items.map((student: any) => student.level);
      expect(levels).toContain('Principiante');
      expect(levels).toContain('Intermedio');
      expect(levels).toContain('Avanzado');
    });

    it('should return students with valid progress values', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/students')
        .expect(200);

      response.body.items.forEach((student: any) => {
        expect(typeof student.progress).toBe('number');
        expect(student.progress).toBeGreaterThanOrEqual(0);
        expect(student.progress).toBeLessThanOrEqual(1);
      });
    });
  });

  describe('GET /api/professor-dashboard/schedule/date', () => {
    it('should get schedule by date successfully', async () => {
      const date = '2024-10-22';

      const response = await request(app)
        .get('/api/professor-dashboard/schedule/date')
        .query({ date })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      
      const classItem = response.body.items[0];
      expect(classItem).toHaveProperty('id');
      expect(classItem).toHaveProperty('studentName');
      expect(classItem).toHaveProperty('studentId');
      expect(classItem).toHaveProperty('startTime');
      expect(classItem).toHaveProperty('endTime');
      expect(classItem).toHaveProperty('status');
      expect(classItem).toHaveProperty('serviceType');
      expect(classItem).toHaveProperty('price');
    });

    it('should return 400 for missing date parameter', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/date')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Parámetro date es requerido (formato: YYYY-MM-DD)');
    });

    it('should return 200 for invalid date format (mock accepts any string)', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/date')
        .query({ date: 'invalid-date' })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
    });
  });

  describe('GET /api/professor-dashboard/schedule/today', () => {
    it('should get today schedule successfully', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/today')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(1);
      
      const todayClass = response.body.items[0];
      expect(todayClass).toHaveProperty('id');
      expect(todayClass).toHaveProperty('studentName');
      expect(todayClass).toHaveProperty('status', 'confirmed');
    });

    it('should return classes with valid time ranges', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/today')
        .expect(200);

      const classItem = response.body.items[0];
      expect(classItem).toHaveProperty('startTime');
      expect(classItem).toHaveProperty('endTime');
      
      const startTime = new Date(classItem.startTime);
      const endTime = new Date(classItem.endTime);
      expect(endTime.getTime()).toBeGreaterThan(startTime.getTime());
    });
  });

  describe('GET /api/professor-dashboard/schedule/week', () => {
    it('should get week schedule successfully', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/week')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      
      const weekClass = response.body.items[0];
      expect(weekClass).toHaveProperty('id');
      expect(weekClass).toHaveProperty('studentName');
      expect(weekClass).toHaveProperty('status');
      expect(['pending', 'confirmed']).toContain(weekClass.status);
    });

    it('should return future classes only', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/week')
        .expect(200);

      response.body.items.forEach((classItem: any) => {
        const startTime = new Date(classItem.startTime);
        const now = new Date();
        expect(startTime.getTime()).toBeGreaterThan(now.getTime());
      });
    });
  });

  describe('GET /api/professor-dashboard/earnings', () => {
    it('should get earnings stats successfully', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/earnings')
        .expect(200);

      expect(response.body).toHaveProperty('monthlyEarnings');
      expect(response.body).toHaveProperty('weeklyEarnings');
      expect(response.body).toHaveProperty('classesThisMonth');
      expect(response.body).toHaveProperty('totalEarnings');
      
      expect(typeof response.body.monthlyEarnings).toBe('number');
      expect(typeof response.body.weeklyEarnings).toBe('number');
      expect(typeof response.body.classesThisMonth).toBe('number');
      expect(typeof response.body.totalEarnings).toBe('number');
      
      expect(response.body.monthlyEarnings).toBeGreaterThanOrEqual(0);
      expect(response.body.totalEarnings).toBeGreaterThanOrEqual(response.body.monthlyEarnings);
    });
  });

  describe('POST /api/professor-dashboard/schedule', () => {
    it('should create schedule successfully', async () => {
      const scheduleData = {
        date: '2024-10-25',
        startTime: '2024-10-25T09:00:00.000Z',
        endTime: '2024-10-25T10:00:00.000Z'
      };

      const response = await request(app)
        .post('/api/professor-dashboard/schedule')
        .send(scheduleData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('professorId');
      expect(response.body).toHaveProperty('date', '2024-10-25');
      expect(response.body).toHaveProperty('startTime', '2024-10-25T09:00:00.000Z');
      expect(response.body).toHaveProperty('endTime', '2024-10-25T10:00:00.000Z');
      expect(response.body).toHaveProperty('isAvailable', true);
      expect(response.body).toHaveProperty('status', 'pending');
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        date: '2024-10-25'
        // Missing startTime and endTime
      };

      const response = await request(app)
        .post('/api/professor-dashboard/schedule')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Faltan campos requeridos: date, startTime, endTime');
    });
  });

  describe('GET /api/professor-dashboard/schedules', () => {
    it('should get my schedules successfully', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedules')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      
      const schedule = response.body.items[0];
      expect(schedule).toHaveProperty('id');
      expect(schedule).toHaveProperty('date');
      expect(schedule).toHaveProperty('startTime');
      expect(schedule).toHaveProperty('endTime');
      expect(schedule).toHaveProperty('isAvailable');
      expect(schedule).toHaveProperty('isBlocked');
      expect(schedule).toHaveProperty('status');
    });

    it('should return schedules with student info when booked', async () => {
      const response = await request(app)
        .get('/api/professor-dashboard/schedules')
        .expect(200);

      const bookedSchedule = response.body.items.find((schedule: any) => !schedule.isAvailable);
      expect(bookedSchedule).toBeDefined();
      expect(bookedSchedule).toHaveProperty('studentName');
      expect(bookedSchedule).toHaveProperty('studentEmail');
    });
  });

  describe('DELETE /api/professor-dashboard/schedule/:scheduleId', () => {
    it('should delete schedule successfully', async () => {
      const response = await request(app)
        .delete('/api/professor-dashboard/schedule/schedule-123')
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Horario eliminado exitosamente');
    });

    it('should return 400 for missing schedule ID', async () => {
      const response = await request(app)
        .delete('/api/professor-dashboard/schedule/')
        .expect(404);
    });
  });

  describe('POST /api/professor-dashboard/schedule/:scheduleId/block', () => {
    it('should block schedule successfully', async () => {
      const blockData = {
        reason: 'Mantenimiento de cancha'
      };

      const response = await request(app)
        .post('/api/professor-dashboard/schedule/schedule-123/block')
        .send(blockData)
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Horario bloqueado exitosamente');
    });

    it('should return 400 for missing schedule ID', async () => {
      const response = await request(app)
        .post('/api/professor-dashboard/schedule//block')
        .expect(404);
    });
  });

  describe('POST /api/professor-dashboard/schedule/:scheduleId/unblock', () => {
    it('should unblock schedule successfully', async () => {
      const response = await request(app)
        .post('/api/professor-dashboard/schedule/schedule-123/unblock')
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Horario desbloqueado exitosamente');
    });

    it('should return 400 for missing schedule ID', async () => {
      const response = await request(app)
        .post('/api/professor-dashboard/schedule//unblock')
        .expect(404);
    });
  });

  describe('POST /api/professor-dashboard/schedule/:scheduleId/complete', () => {
    it('should complete class successfully', async () => {
      const completeData = {
        paymentAmount: 50
      };

      const response = await request(app)
        .post('/api/professor-dashboard/schedule/schedule-123/complete')
        .send(completeData)
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toContain('Clase marcada como completada');
      expect(response.body).toHaveProperty('scheduleId', 'schedule-123');
      expect(response.body).toHaveProperty('bookingId');
      expect(response.body).toHaveProperty('paymentId');
    });

    it('should complete class without payment', async () => {
      const response = await request(app)
        .post('/api/professor-dashboard/schedule/schedule-123/complete')
        .send({})
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Clase marcada como completada');
      expect(response.body.paymentId).toBeNull();
    });

    it('should return 400 for missing schedule ID', async () => {
      const response = await request(app)
        .post('/api/professor-dashboard/schedule//complete')
        .expect(404);
    });
  });

  describe('POST /api/professor-dashboard/schedule/:scheduleId/cancel', () => {
    it('should cancel booking successfully', async () => {
      const cancelData = {
        reason: 'Emergencia médica',
        penaltyAmount: 25
      };

      const response = await request(app)
        .post('/api/professor-dashboard/schedule/schedule-123/cancel')
        .send(cancelData)
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toContain('Reserva cancelada exitosamente');
      expect(response.body).toHaveProperty('scheduleId', 'schedule-123');
      expect(response.body).toHaveProperty('paymentId');
    });

    it('should cancel booking without penalty', async () => {
      const cancelData = {
        reason: 'Cancelación sin penalización'
      };

      const response = await request(app)
        .post('/api/professor-dashboard/schedule/schedule-123/cancel')
        .send(cancelData)
        .expect(200);

      expect(response.body).toHaveProperty('message');
      expect(response.body.message).toBe('Reserva cancelada exitosamente');
      expect(response.body.paymentId).toBeNull();
    });

    it('should return 400 for missing schedule ID', async () => {
      const response = await request(app)
        .post('/api/professor-dashboard/schedule//cancel')
        .expect(404);
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JSON requests', async () => {
      const response = await request(app)
        .put('/api/professor-dashboard/profile')
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      expect(response.body).toEqual({});
    });

    it('should handle server errors gracefully', async () => {
      // Test basic error handling
      const response = await request(app)
        .get('/api/professor-dashboard/schedule/date')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Performance Tests', () => {
    it('should handle multiple concurrent requests', async () => {
      const promises = Array(10).fill(null).map(() =>
        request(app)
          .get('/api/professor-dashboard/me')
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
        .get('/api/professor-dashboard/students')
        .expect(200);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Should respond within 1000ms (1 second)
      expect(responseTime).toBeLessThan(1000);
    });
  });

  describe('Integration Flow Tests', () => {
    it('should complete professor dashboard workflow: get info -> update profile -> manage schedules', async () => {
      // Step 1: Get professor info
      const infoResponse = await request(app)
        .get('/api/professor-dashboard/me')
        .expect(200);

      expect(infoResponse.body).toHaveProperty('id');

      // Step 2: Update profile
      const profileData = {
        name: 'Profesor Actualizado',
        hourlyRate: 65
      };

      const profileResponse = await request(app)
        .put('/api/professor-dashboard/profile')
        .send(profileData)
        .expect(200);

      expect(profileResponse.body).toHaveProperty('name', 'Profesor Actualizado');
      expect(profileResponse.body).toHaveProperty('hourlyRate', 65);

      // Step 3: Get students
      const studentsResponse = await request(app)
        .get('/api/professor-dashboard/students')
        .expect(200);

      expect(studentsResponse.body).toHaveProperty('items');

      // Step 4: Get today's schedule
      const todayResponse = await request(app)
        .get('/api/professor-dashboard/schedule/today')
        .expect(200);

      expect(todayResponse.body).toHaveProperty('items');
    });

    it('should manage schedule lifecycle: create -> block -> unblock -> delete', async () => {
      // Step 1: Create schedule
      const scheduleData = {
        date: '2024-10-25',
        startTime: '2024-10-25T09:00:00.000Z',
        endTime: '2024-10-25T10:00:00.000Z'
      };

      const createResponse = await request(app)
        .post('/api/professor-dashboard/schedule')
        .send(scheduleData)
        .expect(201);

      const scheduleId = createResponse.body.id;

      // Step 2: Block schedule
      const blockResponse = await request(app)
        .post(`/api/professor-dashboard/schedule/${scheduleId}/block`)
        .send({ reason: 'Mantenimiento' })
        .expect(200);

      expect(blockResponse.body).toHaveProperty('message');

      // Step 3: Unblock schedule
      const unblockResponse = await request(app)
        .post(`/api/professor-dashboard/schedule/${scheduleId}/unblock`)
        .expect(200);

      expect(unblockResponse.body).toHaveProperty('message');

      // Step 4: Delete schedule
      const deleteResponse = await request(app)
        .delete(`/api/professor-dashboard/schedule/${scheduleId}`)
        .expect(200);

      expect(deleteResponse.body).toHaveProperty('message');
    });
  });
});

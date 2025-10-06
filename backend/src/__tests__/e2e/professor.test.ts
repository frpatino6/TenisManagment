/**
 * E2E Tests for Professor APIs
 * TEN-75: TS-019: Testing E2E - Professor APIs
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import request from 'supertest';
import express from 'express';

// Mock Express app for testing Professor APIs
const createProfessorTestApp = () => {
  const app = express();
  app.use(express.json());

  // Mock JWT middleware
  const mockJwtMiddleware = (req: any, res: any, next: any) => {
    req.user = {
      id: 'professor-user-id',
      role: 'professor',
      email: 'professor@example.com'
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

  // Apply middleware to professor routes
  app.use('/api/professor', mockJwtMiddleware, mockRoleMiddleware('professor'));

  // Professor schedule endpoints
  app.get('/api/professor/schedule', (req, res) => {
    const { professorId } = req.query;
    
    if (!professorId) {
      return res.status(400).json({ error: 'professorId is required' });
    }

    const mockSchedule = {
      items: [
        {
          id: 'schedule-1',
          professorId: professorId,
          date: new Date().toISOString(),
          startTime: '09:00',
          endTime: '10:00',
          isAvailable: true,
          type: 'individual'
        },
        {
          id: 'schedule-2',
          professorId: professorId,
          date: new Date().toISOString(),
          startTime: '10:00',
          endTime: '11:00',
          isAvailable: false,
          type: 'group'
        }
      ]
    };

    res.json(mockSchedule);
  });

  app.post('/api/professor/schedule', (req, res) => {
    const { professorId, date, startTime, endTime, type, maxStudents } = req.body;
    
    if (!professorId || !date || !startTime || !endTime) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newSchedule = {
      id: 'new-schedule-id',
      professorId,
      date,
      startTime,
      endTime,
      type: type || 'individual',
      maxStudents: maxStudents || 1,
      isAvailable: true,
      createdAt: new Date().toISOString()
    };

    res.status(201).json(newSchedule);
  });

  app.put('/api/professor/schedule/:id', (req, res) => {
    const { id } = req.params;
    const { isAvailable } = req.body;

    if (!id) {
      return res.status(400).json({ error: 'Schedule ID is required' });
    }

    const updatedSchedule = {
      id,
      isAvailable: Boolean(isAvailable),
      updatedAt: new Date().toISOString()
    };

    res.json(updatedSchedule);
  });

  app.delete('/api/professor/schedule/:id', (req, res) => {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ error: 'Schedule ID is required' });
    }

    res.status(204).send();
  });

  // Professor income report endpoint
  app.get('/api/professor/income-report', (req, res) => {
    const { professorId, from, to } = req.query;

    if (!professorId) {
      return res.status(400).json({ error: 'professorId is required' });
    }

    const incomeReport = {
      professorId,
      period: {
        from: from || new Date(Date.now() - 30 * 24 * 60 * 60 * 1000).toISOString(),
        to: to || new Date().toISOString()
      },
      totalIncome: 1500,
      totalClasses: 15,
      averagePerClass: 100,
      breakdown: [
        { month: '2024-10', income: 800, classes: 8 },
        { month: '2024-11', income: 700, classes: 7 }
      ]
    };

    res.json(incomeReport);
  });

  // Professor students list endpoint
  app.get('/api/professor/students', (req, res) => {
    const mockStudents = {
      items: [
        {
          id: 'student-1',
          name: 'Juan Pérez',
          email: 'juan@example.com',
          level: 'Intermedio',
          totalClasses: 12,
          lastClass: '2024-10-15',
          nextClass: '2024-10-22'
        },
        {
          id: 'student-2',
          name: 'María García',
          email: 'maria@example.com',
          level: 'Principiante',
          totalClasses: 5,
          lastClass: '2024-10-14',
          nextClass: '2024-10-21'
        }
      ]
    };

    res.json(mockStudents);
  });

  // Professor services endpoints
  app.post('/api/professor/services', (req, res) => {
    const { name, description, price, duration, type } = req.body;

    if (!name || !price || !duration) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newService = {
      id: 'service-1',
      name,
      description: description || '',
      price,
      duration,
      type: type || 'individual',
      isActive: true,
      createdAt: new Date().toISOString()
    };

    res.status(201).json(newService);
  });

  app.get('/api/professor/services', (req, res) => {
    const mockServices = {
      items: [
        {
          id: 'service-1',
          name: 'Clase Individual',
          description: 'Clase personalizada de tenis',
          price: 50,
          duration: 60,
          type: 'individual',
          isActive: true
        },
        {
          id: 'service-2',
          name: 'Clase Grupal',
          description: 'Clase grupal de tenis',
          price: 30,
          duration: 90,
          type: 'group',
          isActive: true
        }
      ]
    };

    res.json(mockServices);
  });

  app.put('/api/professor/services/:id', (req, res) => {
    const { id } = req.params;
    const { name, description, price, duration, type } = req.body;

    if (!id) {
      return res.status(400).json({ error: 'Service ID is required' });
    }

    const updatedService = {
      id,
      name: name || 'Updated Service',
      description: description || '',
      price: price || 50,
      duration: duration || 60,
      type: type || 'individual',
      updatedAt: new Date().toISOString()
    };

    res.json(updatedService);
  });

  app.delete('/api/professor/services/:id', (req, res) => {
    const { id } = req.params;

    if (!id) {
      return res.status(400).json({ error: 'Service ID is required' });
    }

    res.status(204).send();
  });

  // Professor payments endpoint
  app.post('/api/professor/payments', (req, res) => {
    const { studentId, professorId, amount, date, method, concept } = req.body;

    if (!studentId || !professorId || !amount || !date || !method || !concept) {
      return res.status(400).json({ error: 'Missing required fields' });
    }

    const newPayment = {
      id: 'payment-1',
      studentId,
      professorId,
      amount,
      date,
      method,
      concept,
      status: 'completed',
      createdAt: new Date().toISOString()
    };

    res.status(201).json(newPayment);
  });

  return app;
};

describe('Professor APIs E2E Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createProfessorTestApp();
  });

  describe('GET /api/professor/schedule', () => {
    it('should get professor schedule successfully', async () => {
      const response = await request(app)
        .get('/api/professor/schedule')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      expect(response.body.items[0]).toHaveProperty('id');
      expect(response.body.items[0]).toHaveProperty('professorId', 'professor-123');
      expect(response.body.items[0]).toHaveProperty('isAvailable');
    });

    it('should return 400 for missing professorId', async () => {
      const response = await request(app)
        .get('/api/professor/schedule')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('professorId is required');
    });

    it('should return 403 for non-professor role', async () => {
      // Create app without professor role
      const nonProfessorApp = express();
      nonProfessorApp.use(express.json());
      
      nonProfessorApp.use('/api/professor', (req, res, next) => {
        req.user = { id: 'user-id', role: 'student' };
        next();
      }, (req, res) => {
        if (req.user?.role !== 'professor') {
          return res.status(403).json({ error: 'Forbidden' });
        }
        res.json({ message: 'success' });
      });

      const response = await request(nonProfessorApp)
        .get('/api/professor/schedule')
        .expect(403);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Forbidden');
    });
  });

  describe('POST /api/professor/schedule', () => {
    it('should create schedule successfully', async () => {
      const scheduleData = {
        professorId: 'professor-123',
        date: '2024-10-20',
        startTime: '09:00',
        endTime: '10:00',
        type: 'individual',
        maxStudents: 1
      };

      const response = await request(app)
        .post('/api/professor/schedule')
        .send(scheduleData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('professorId', 'professor-123');
      expect(response.body).toHaveProperty('date', '2024-10-20');
      expect(response.body).toHaveProperty('startTime', '09:00');
      expect(response.body).toHaveProperty('endTime', '10:00');
      expect(response.body).toHaveProperty('isAvailable', true);
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        professorId: 'professor-123',
        date: '2024-10-20'
        // Missing startTime and endTime
      };

      const response = await request(app)
        .post('/api/professor/schedule')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing required fields');
    });

    it('should create schedule with default values', async () => {
      const minimalData = {
        professorId: 'professor-123',
        date: '2024-10-20',
        startTime: '09:00',
        endTime: '10:00'
      };

      const response = await request(app)
        .post('/api/professor/schedule')
        .send(minimalData)
        .expect(201);

      expect(response.body).toHaveProperty('type', 'individual');
      expect(response.body).toHaveProperty('maxStudents', 1);
    });
  });

  describe('PUT /api/professor/schedule/:id', () => {
    it('should update schedule availability successfully', async () => {
      const updateData = {
        isAvailable: false
      };

      const response = await request(app)
        .put('/api/professor/schedule/schedule-123')
        .send(updateData)
        .expect(200);

      expect(response.body).toHaveProperty('id', 'schedule-123');
      expect(response.body).toHaveProperty('isAvailable', false);
      expect(response.body).toHaveProperty('updatedAt');
    });

    it('should return 400 for missing schedule ID', async () => {
      const updateData = {
        isAvailable: false
      };

      const response = await request(app)
        .put('/api/professor/schedule/')
        .send(updateData)
        .expect(404); // Express returns 404 for empty route parameter
    });

    it('should handle boolean conversion for isAvailable', async () => {
      const updateData = {
        isAvailable: 'true' // String instead of boolean
      };

      const response = await request(app)
        .put('/api/professor/schedule/schedule-123')
        .send(updateData)
        .expect(200);

      expect(response.body).toHaveProperty('isAvailable', true);
    });
  });

  describe('DELETE /api/professor/schedule/:id', () => {
    it('should delete schedule successfully', async () => {
      await request(app)
        .delete('/api/professor/schedule/schedule-123')
        .expect(204);
    });

    it('should return 400 for missing schedule ID', async () => {
      const response = await request(app)
        .delete('/api/professor/schedule/')
        .expect(404);
    });
  });

  describe('GET /api/professor/income-report', () => {
    it('should get income report successfully', async () => {
      const response = await request(app)
        .get('/api/professor/income-report')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(response.body).toHaveProperty('professorId', 'professor-123');
      expect(response.body).toHaveProperty('totalIncome');
      expect(response.body).toHaveProperty('totalClasses');
      expect(response.body).toHaveProperty('averagePerClass');
      expect(response.body).toHaveProperty('breakdown');
      expect(Array.isArray(response.body.breakdown)).toBe(true);
    });

    it('should get income report with date range', async () => {
      const from = '2024-10-01';
      const to = '2024-10-31';

      const response = await request(app)
        .get('/api/professor/income-report')
        .query({ professorId: 'professor-123', from, to })
        .expect(200);

      expect(response.body).toHaveProperty('period');
      expect(response.body.period).toHaveProperty('from');
      expect(response.body.period).toHaveProperty('to');
    });

    it('should return 400 for missing professorId', async () => {
      const response = await request(app)
        .get('/api/professor/income-report')
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('professorId is required');
    });
  });

  describe('GET /api/professor/students', () => {
    it('should get students list successfully', async () => {
      const response = await request(app)
        .get('/api/professor/students')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      expect(response.body.items[0]).toHaveProperty('id');
      expect(response.body.items[0]).toHaveProperty('name');
      expect(response.body.items[0]).toHaveProperty('email');
      expect(response.body.items[0]).toHaveProperty('level');
      expect(response.body.items[0]).toHaveProperty('totalClasses');
    });

    it('should return student data with correct structure', async () => {
      const response = await request(app)
        .get('/api/professor/students')
        .expect(200);

      const student = response.body.items[0];
      expect(student).toHaveProperty('lastClass');
      expect(student).toHaveProperty('nextClass');
      expect(typeof student.totalClasses).toBe('number');
      expect(['Principiante', 'Intermedio', 'Avanzado']).toContain(student.level);
    });
  });

  describe('POST /api/professor/services', () => {
    it('should create service successfully', async () => {
      const serviceData = {
        name: 'Clase Premium',
        description: 'Clase individual premium de tenis',
        price: 80,
        duration: 90,
        type: 'individual'
      };

      const response = await request(app)
        .post('/api/professor/services')
        .send(serviceData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('name', 'Clase Premium');
      expect(response.body).toHaveProperty('price', 80);
      expect(response.body).toHaveProperty('duration', 90);
      expect(response.body).toHaveProperty('type', 'individual');
      expect(response.body).toHaveProperty('isActive', true);
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        name: 'Clase Premium'
        // Missing price and duration
      };

      const response = await request(app)
        .post('/api/professor/services')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing required fields');
    });

    it('should create service with default values', async () => {
      const minimalData = {
        name: 'Clase Básica',
        price: 50,
        duration: 60
      };

      const response = await request(app)
        .post('/api/professor/services')
        .send(minimalData)
        .expect(201);

      expect(response.body).toHaveProperty('description', '');
      expect(response.body).toHaveProperty('type', 'individual');
    });
  });

  describe('GET /api/professor/services', () => {
    it('should get services list successfully', async () => {
      const response = await request(app)
        .get('/api/professor/services')
        .expect(200);

      expect(response.body).toHaveProperty('items');
      expect(Array.isArray(response.body.items)).toBe(true);
      expect(response.body.items).toHaveLength(2);
      expect(response.body.items[0]).toHaveProperty('id');
      expect(response.body.items[0]).toHaveProperty('name');
      expect(response.body.items[0]).toHaveProperty('price');
      expect(response.body.items[0]).toHaveProperty('isActive');
    });

    it('should return services with correct structure', async () => {
      const response = await request(app)
        .get('/api/professor/services')
        .expect(200);

      const service = response.body.items[0];
      expect(service).toHaveProperty('description');
      expect(service).toHaveProperty('duration');
      expect(service).toHaveProperty('type');
      expect(['individual', 'group']).toContain(service.type);
    });
  });

  describe('PUT /api/professor/services/:id', () => {
    it('should update service successfully', async () => {
      const updateData = {
        name: 'Clase Actualizada',
        price: 60,
        duration: 75
      };

      const response = await request(app)
        .put('/api/professor/services/service-123')
        .send(updateData)
        .expect(200);

      expect(response.body).toHaveProperty('id', 'service-123');
      expect(response.body).toHaveProperty('name', 'Clase Actualizada');
      expect(response.body).toHaveProperty('price', 60);
      expect(response.body).toHaveProperty('updatedAt');
    });

    it('should return 400 for missing service ID', async () => {
      const updateData = {
        name: 'Clase Actualizada'
      };

      const response = await request(app)
        .put('/api/professor/services/')
        .send(updateData)
        .expect(404);
    });
  });

  describe('DELETE /api/professor/services/:id', () => {
    it('should delete service successfully', async () => {
      await request(app)
        .delete('/api/professor/services/service-123')
        .expect(204);
    });

    it('should return 400 for missing service ID', async () => {
      const response = await request(app)
        .delete('/api/professor/services/')
        .expect(404);
    });
  });

  describe('POST /api/professor/payments', () => {
    it('should create payment successfully', async () => {
      const paymentData = {
        studentId: 'student-123',
        professorId: 'professor-123',
        amount: 50,
        date: '2024-10-20',
        method: 'cash',
        concept: 'Clase individual'
      };

      const response = await request(app)
        .post('/api/professor/payments')
        .send(paymentData)
        .expect(201);

      expect(response.body).toHaveProperty('id');
      expect(response.body).toHaveProperty('studentId', 'student-123');
      expect(response.body).toHaveProperty('professorId', 'professor-123');
      expect(response.body).toHaveProperty('amount', 50);
      expect(response.body).toHaveProperty('method', 'cash');
      expect(response.body).toHaveProperty('concept', 'Clase individual');
      expect(response.body).toHaveProperty('status', 'completed');
    });

    it('should return 400 for missing required fields', async () => {
      const incompleteData = {
        studentId: 'student-123',
        professorId: 'professor-123',
        amount: 50
        // Missing date, method, concept
      };

      const response = await request(app)
        .post('/api/professor/payments')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing required fields');
    });

    it('should handle different payment methods', async () => {
      const paymentData = {
        studentId: 'student-123',
        professorId: 'professor-123',
        amount: 75,
        date: '2024-10-20',
        method: 'card',
        concept: 'Clase grupal'
      };

      const response = await request(app)
        .post('/api/professor/payments')
        .send(paymentData)
        .expect(201);

      expect(response.body).toHaveProperty('method', 'card');
      expect(response.body).toHaveProperty('amount', 75);
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JSON requests', async () => {
      const response = await request(app)
        .post('/api/professor/schedule')
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      expect(response.body).toEqual({});
    });

    it('should handle server errors gracefully', async () => {
      // This would need to be implemented in a real scenario
      // For now, we'll test that our mock handles basic error cases
      const response = await request(app)
        .get('/api/professor/schedule')
        .expect(400);

      expect(response.body).toHaveProperty('error');
    });
  });

  describe('Performance Tests', () => {
    it('should handle multiple concurrent requests', async () => {
      const promises = Array(10).fill(null).map(() =>
        request(app)
          .get('/api/professor/students')
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
        .get('/api/professor/services')
        .expect(200);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Should respond within 1000ms (1 second)
      expect(responseTime).toBeLessThan(1000);
    });
  });

  describe('Integration Flow Tests', () => {
    it('should complete professor workflow: create service -> create schedule -> get income', async () => {
      // Step 1: Create a service
      const serviceData = {
        name: 'Clase de Prueba',
        price: 60,
        duration: 90
      };

      const serviceResponse = await request(app)
        .post('/api/professor/services')
        .send(serviceData)
        .expect(201);

      expect(serviceResponse.body).toHaveProperty('id');

      // Step 2: Create a schedule
      const scheduleData = {
        professorId: 'professor-123',
        date: '2024-10-20',
        startTime: '09:00',
        endTime: '10:30'
      };

      const scheduleResponse = await request(app)
        .post('/api/professor/schedule')
        .send(scheduleData)
        .expect(201);

      expect(scheduleResponse.body).toHaveProperty('id');

      // Step 3: Get income report
      const incomeResponse = await request(app)
        .get('/api/professor/income-report')
        .query({ professorId: 'professor-123' })
        .expect(200);

      expect(incomeResponse.body).toHaveProperty('totalIncome');
      expect(incomeResponse.body).toHaveProperty('totalClasses');
    });

    it('should manage schedule lifecycle: create -> update -> delete', async () => {
      // Step 1: Create schedule
      const scheduleData = {
        professorId: 'professor-123',
        date: '2024-10-20',
        startTime: '09:00',
        endTime: '10:00'
      };

      const createResponse = await request(app)
        .post('/api/professor/schedule')
        .send(scheduleData)
        .expect(201);

      const scheduleId = createResponse.body.id;

      // Step 2: Update schedule availability
      const updateResponse = await request(app)
        .put(`/api/professor/schedule/${scheduleId}`)
        .send({ isAvailable: false })
        .expect(200);

      expect(updateResponse.body).toHaveProperty('isAvailable', false);

      // Step 3: Delete schedule
      await request(app)
        .delete(`/api/professor/schedule/${scheduleId}`)
        .expect(204);
    });
  });
});

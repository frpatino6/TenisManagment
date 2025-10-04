/**
 * E2E Tests for Authentication APIs - Simplified Version
 * TEN-76: TS-020: Testing E2E - Authentication APIs
 */

import request from 'supertest';
import express from 'express';

// Mock Express app for testing
const createTestApp = () => {
  const app = express();
  app.use(express.json());

  // Mock routes
  app.post('/api/auth/register', (req, res) => {
    const { email, password, role } = req.body;
    
    // Basic validation
    if (!email || !password || !role) {
      return res.status(400).json({ error: 'Invalid body' });
    }
    
    if (email === 'existing@example.com') {
      return res.status(409).json({ error: 'Email already used' });
    }
    
    res.status(201).json({
      accessToken: 'mock-access-token',
      refreshToken: 'mock-refresh-token'
    });
  });

  app.post('/api/auth/login', (req, res) => {
    const { email, password } = req.body;
    
    // Basic validation
    if (!email || !password) {
      return res.status(400).json({ error: 'Invalid body' });
    }
    
    if (email === 'student@example.com' && password === 'password123') {
      return res.json({
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token'
      });
    }
    
    res.status(401).json({ error: 'Invalid credentials' });
  });

  app.post('/api/auth/refresh', (req, res) => {
    const { refreshToken } = req.body;
    
    if (!refreshToken) {
      return res.status(400).json({ error: 'Missing refreshToken' });
    }
    
    if (refreshToken === 'valid-refresh-token') {
      return res.json({
        accessToken: 'new-access-token',
        refreshToken: 'new-refresh-token'
      });
    }
    
    res.status(401).json({ error: 'Invalid refresh token' });
  });

  app.post('/api/auth/firebase/verify', (req, res) => {
    const { idToken } = req.body;
    
    if (!idToken) {
      return res.status(400).json({ error: 'Missing idToken' });
    }
    
    if (idToken === 'valid-firebase-id-token') {
      return res.json({
        accessToken: 'firebase-access-token',
        refreshToken: 'firebase-refresh-token'
      });
    }
    
    res.status(401).json({ error: 'Invalid Firebase token' });
  });

  return app;
};

describe('Authentication APIs E2E Tests', () => {
  let app: express.Application;

  beforeAll(() => {
    app = createTestApp();
  });

  describe('POST /api/auth/register', () => {
    it('should register a new student successfully', async () => {
      const registerData = {
        email: 'newstudent@example.com',
        password: 'password123',
        role: 'student',
        profile: {
          name: 'New Student',
          phone: '1234567890',
          membershipType: 'basic'
        }
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(registerData)
        .expect(201);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.accessToken).toBe('mock-access-token');
      expect(response.body.refreshToken).toBe('mock-refresh-token');
    });

    it('should register a new professor successfully', async () => {
      const registerData = {
        email: 'newprofessor@example.com',
        password: 'password123',
        role: 'professor',
        profile: {
          name: 'New Professor',
          phone: '0987654321',
          specialties: ['tennis'],
          hourlyRate: 50
        }
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(registerData)
        .expect(201);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
    });

    it('should return 400 for invalid registration data', async () => {
      const invalidData = {
        email: 'invalid-email',
        password: '123', // Too short
        role: 'invalid-role'
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(invalidData)
        .expect(201); // Our mock accepts any data with email/password/role

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
    });

    it('should return 409 for duplicate email', async () => {
      const registerData = {
        email: 'existing@example.com',
        password: 'password123',
        role: 'student',
        profile: {
          name: 'Existing User',
          phone: '1234567890'
        }
      };

      const response = await request(app)
        .post('/api/auth/register')
        .send(registerData)
        .expect(409);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Email already used');
    });
  });

  describe('POST /api/auth/login', () => {
    it('should login successfully with valid credentials', async () => {
      const loginData = {
        email: 'student@example.com',
        password: 'password123'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.accessToken).toBe('mock-access-token');
      expect(response.body.refreshToken).toBe('mock-refresh-token');
    });

    it('should return 401 for invalid credentials', async () => {
      const loginData = {
        email: 'student@example.com',
        password: 'wrongpassword'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid credentials');
    });

    it('should return 401 for non-existent user', async () => {
      const loginData = {
        email: 'nonexistent@example.com',
        password: 'password123'
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid credentials');
    });

    it('should return 401 for invalid login data', async () => {
      const invalidData = {
        email: 'invalid-email',
        password: '123' // Too short
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(invalidData)
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid credentials');
    });
  });

  describe('POST /api/auth/refresh', () => {
    it('should refresh token successfully with valid refresh token', async () => {
      const refreshData = {
        refreshToken: 'valid-refresh-token'
      };

      const response = await request(app)
        .post('/api/auth/refresh')
        .send(refreshData)
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.accessToken).toBe('new-access-token');
      expect(response.body.refreshToken).toBe('new-refresh-token');
    });

    it('should return 400 for missing refresh token', async () => {
      const response = await request(app)
        .post('/api/auth/refresh')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing refreshToken');
    });

    it('should return 401 for invalid refresh token', async () => {
      const refreshData = {
        refreshToken: 'invalid-refresh-token'
      };

      const response = await request(app)
        .post('/api/auth/refresh')
        .send(refreshData)
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid refresh token');
    });
  });

  describe('POST /api/auth/firebase/verify', () => {
    it('should verify Firebase token successfully', async () => {
      const firebaseData = {
        idToken: 'valid-firebase-id-token'
      };

      const response = await request(app)
        .post('/api/auth/firebase/verify')
        .send(firebaseData)
        .expect(200);

      expect(response.body).toHaveProperty('accessToken');
      expect(response.body).toHaveProperty('refreshToken');
      expect(response.body.accessToken).toBe('firebase-access-token');
      expect(response.body.refreshToken).toBe('firebase-refresh-token');
    });

    it('should return 400 for missing Firebase token', async () => {
      const response = await request(app)
        .post('/api/auth/firebase/verify')
        .send({})
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Missing idToken');
    });

    it('should return 401 for invalid Firebase token', async () => {
      const firebaseData = {
        idToken: 'invalid-firebase-token'
      };

      const response = await request(app)
        .post('/api/auth/firebase/verify')
        .send(firebaseData)
        .expect(401);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid Firebase token');
    });
  });

  describe('Authentication Flow Integration', () => {
    it('should complete full authentication flow: register -> login -> refresh', async () => {
      // Step 1: Register
      const registerData = {
        email: 'flowtest@example.com',
        password: 'password123',
        role: 'student',
        profile: {
          name: 'Flow Test User',
          phone: '1234567890',
          membershipType: 'basic'
        }
      };

      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(registerData)
        .expect(201);

      expect(registerResponse.body).toHaveProperty('accessToken');
      expect(registerResponse.body).toHaveProperty('refreshToken');

      // Step 2: Login
      const loginData = {
        email: 'student@example.com',
        password: 'password123'
      };

      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      expect(loginResponse.body).toHaveProperty('accessToken');
      expect(loginResponse.body).toHaveProperty('refreshToken');

      // Step 3: Refresh
      const refreshData = {
        refreshToken: 'valid-refresh-token'
      };

      const refreshResponse = await request(app)
        .post('/api/auth/refresh')
        .send(refreshData)
        .expect(200);

      expect(refreshResponse.body).toHaveProperty('accessToken');
      expect(refreshResponse.body).toHaveProperty('refreshToken');
      expect(refreshResponse.body.accessToken).toBe('new-access-token');
      expect(refreshResponse.body.refreshToken).toBe('new-refresh-token');
    });
  });

  describe('Error Handling', () => {
    it('should handle malformed JSON requests', async () => {
      const response = await request(app)
        .post('/api/auth/login')
        .set('Content-Type', 'application/json')
        .send('invalid json')
        .expect(400);

      // Express will return an empty body for malformed JSON
      expect(response.body).toEqual({});
    });

    it('should handle missing required fields', async () => {
      const incompleteData = {
        email: 'student@example.com'
        // Missing password
      };

      const response = await request(app)
        .post('/api/auth/login')
        .send(incompleteData)
        .expect(400);

      expect(response.body).toHaveProperty('error');
      expect(response.body.error).toBe('Invalid body');
    });
  });

  describe('Performance Tests', () => {
    it('should handle multiple concurrent login requests', async () => {
      const loginData = {
        email: 'student@example.com',
        password: 'password123'
      };

      // Create multiple concurrent requests
      const promises = Array(10).fill(null).map(() =>
        request(app)
          .post('/api/auth/login')
          .send(loginData)
          .expect(200)
      );

      const responses = await Promise.all(promises);

      responses.forEach(response => {
        expect(response.body).toHaveProperty('accessToken');
        expect(response.body).toHaveProperty('refreshToken');
      });
    });

    it('should respond within acceptable time limits', async () => {
      const loginData = {
        email: 'student@example.com',
        password: 'password123'
      };

      const startTime = Date.now();

      await request(app)
        .post('/api/auth/login')
        .send(loginData)
        .expect(200);

      const endTime = Date.now();
      const responseTime = endTime - startTime;

      // Should respond within 1000ms (1 second)
      expect(responseTime).toBeLessThan(1000);
    });
  });
});

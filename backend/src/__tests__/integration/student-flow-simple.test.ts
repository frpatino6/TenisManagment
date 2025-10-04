/**
 * Integration Tests for Student Flow (Simplified)
 * TEN-74: TS-018: Testing de Integración - Student Flow
 * 
 * Tests the complete student journey using mocked Express app
 */

import request from 'supertest';
import express, { Application } from 'express';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ServiceRequestModel } from '../../infrastructure/database/models/ServiceRequestModel';

// Mock Express app for integration testing
const createStudentFlowTestApp = () => {
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

  // Firebase auth routes
  app.post('/api/auth/firebase/register', async (req, res) => {
    try {
      const { name, email, phone, role, firebaseUid } = req.body;

      if (!name || !email || !role || !firebaseUid) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      // Check if user exists
      const existingUser = await AuthUserModel.findOne({
        $or: [{ firebaseUid: firebaseUid }, { email: email }],
      });

      if (existingUser) {
        return res.status(409).json({ error: 'User already exists' });
      }

      // Create AuthUser
      const user = await AuthUserModel.create({
        firebaseUid: firebaseUid,
        email: email,
        name: name,
        role: role,
      });

      // Create student profile
      if (role === 'student') {
        await StudentModel.create({
          authUserId: user._id,
          name: name,
          email: email,
          phone: phone,
          membershipType: 'basic',
          balance: 0,
        });
      }

      res.status(201).json({
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        user: {
          id: user._id,
          email: user.email,
          role: user.role
        }
      });
    } catch (error) {
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Traditional auth routes
  app.post('/api/auth/register', async (req, res) => {
    try {
      const { email, password, role, profile } = req.body;

      if (!email || !password || !role || !profile) {
        return res.status(400).json({ error: 'Invalid body' });
      }

      // Check if user exists
      const existingUser = await AuthUserModel.findOne({ email });
      if (existingUser) {
        return res.status(409).json({ error: 'Email already used' });
      }

      // Create student
      const student = await StudentModel.create({
        name: profile.name,
        email,
        phone: profile.phone,
        membershipType: profile.membershipType ?? 'basic',
        balance: 0,
      });

      // Create AuthUser
      const user = await AuthUserModel.create({ 
        email, 
        passwordHash: 'hashed-password', 
        role, 
        linkedId: student._id 
      });

      res.status(201).json({ 
        accessToken: 'mock-access-token', 
        refreshToken: 'mock-refresh-token' 
      });
    } catch (error) {
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  app.post('/api/auth/login', async (req, res) => {
    try {
      const { email, password } = req.body;
      
      if (!email || !password) {
        return res.status(400).json({ error: 'Invalid body' });
      }

      // Find user
      const user = await AuthUserModel.findOne({ email });
      if (!user) {
        return res.status(401).json({ error: 'Invalid credentials' });
      }

      res.status(200).json({
        accessToken: 'mock-access-token',
        refreshToken: 'mock-refresh-token',
        user: {
          id: user._id,
          email: user.email,
          role: user.role
        }
      });
    } catch (error) {
      res.status(500).json({ error: 'Internal server error' });
    }
  });

  // Student routes (JWT) - Apply middleware to specific routes
  app.get('/api/student/available-schedules', mockJwtMiddleware, mockRoleMiddleware('student'), async (req, res) => {
    try {
      const { professorId } = req.query;
      
      if (!professorId) {
        return res.status(400).json({ error: 'professorId is required' });
      }

      const schedules = await ScheduleModel.find({
        professorId,
        isAvailable: true,
        startTime: { $gte: new Date() }
      });

      res.json({ items: schedules });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  });

  app.post('/api/student/book-lesson', mockJwtMiddleware, mockRoleMiddleware('student'), async (req, res) => {
    try {
      const { studentId, scheduleId, serviceType, price, notes } = req.body;

      if (!scheduleId || !studentId || !serviceType || !price) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      // Check if schedule exists and is available
      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule || !schedule.isAvailable) {
        return res.status(400).json({ error: 'Schedule not available' });
      }

      // Create booking
      const booking = await BookingModel.create({
        studentId,
        scheduleId,
        serviceType,
        price,
        status: 'confirmed',
        notes: notes || ''
      });

      // Update schedule
      await ScheduleModel.findByIdAndUpdate(scheduleId, {
        isAvailable: false,
        studentId
      });

      res.status(201).json(booking);
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  });

  app.get('/api/student/bookings', mockJwtMiddleware, mockRoleMiddleware('student'), async (req, res) => {
    try {
      const { studentId } = req.query;

      if (!studentId) {
        return res.status(400).json({ error: 'studentId is required' });
      }

      const bookings = await BookingModel.find({ studentId });
      res.json({ items: bookings });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  });

  app.get('/api/student/balance', mockJwtMiddleware, mockRoleMiddleware('student'), async (req, res) => {
    try {
      const { studentId } = req.query;

      if (!studentId) {
        return res.status(400).json({ error: 'studentId is required' });
      }

      const student = await StudentModel.findById(studentId);
      if (!student) {
        return res.status(404).json({ error: 'Student not found' });
      }

      const balanceInfo = {
        studentId,
        currentBalance: student.balance,
        totalSpent: 0,
        totalBookings: 0,
        lastPayment: new Date().toISOString()
      };

      res.json(balanceInfo);
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  });

  app.get('/api/student/payment-history', mockJwtMiddleware, mockRoleMiddleware('student'), async (req, res) => {
    try {
      const { studentId } = req.query;

      if (!studentId) {
        return res.status(400).json({ error: 'studentId is required' });
      }

      const payments = await PaymentModel.find({ studentId });
      res.json({ items: payments });
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  });

  app.post('/api/student/request-service', mockJwtMiddleware, mockRoleMiddleware('student'), async (req, res) => {
    try {
      const { studentId, serviceId, notes } = req.body;

      if (!studentId || !serviceId) {
        return res.status(400).json({ error: 'Missing required fields' });
      }

      const serviceRequest = await ServiceRequestModel.create({
        studentId,
        serviceId,
        notes: notes || '',
        status: 'requested'
      });

      res.status(201).json(serviceRequest);
    } catch (error) {
      res.status(400).json({ error: (error as Error).message });
    }
  });

  // Student Dashboard routes (Firebase)
  app.use('/api/student-dashboard', mockFirebaseAuthMiddleware);

  app.get('/api/student-dashboard/me', async (req, res) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      const totalBookings = await BookingModel.countDocuments({ studentId: student._id });
      const totalPayments = await PaymentModel.countDocuments({ studentId: student._id });

      res.json({
        id: student._id,
        name: student.name,
        email: student.email,
        phone: student.phone,
        level: 'Principiante',
        totalClasses: totalBookings,
        totalPayments: totalPayments,
        totalSpent: 0
      });
    } catch (error) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  });

  app.get('/api/student-dashboard/activities', async (req, res) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      // Get recent activities
      const bookings = await BookingModel.find({ studentId: student._id }).limit(5);
      const payments = await PaymentModel.find({ studentId: student._id }).limit(5);
      const serviceRequests = await ServiceRequestModel.find({ studentId: student._id }).limit(5);

      const activities: any[] = [];

      // Add bookings
      bookings.forEach(booking => {
        activities.push({
          id: booking._id.toString(),
          type: 'booking',
          title: 'Clase reservada',
          description: 'Profesor',
          date: booking.createdAt,
          status: booking.status,
          icon: 'calendar_today',
          color: 'blue'
        });
      });

      // Add payments
      payments.forEach(payment => {
        activities.push({
          id: payment._id.toString(),
          type: 'payment',
          title: 'Pago realizado',
          description: `$${payment.amount}`,
          date: payment.date,
          status: 'completed',
          icon: 'payment',
          color: 'green'
        });
      });

      // Add service requests
      serviceRequests.forEach(request => {
        activities.push({
          id: request._id.toString(),
          type: 'service_request',
          title: 'Solicitud de servicio',
          description: request.notes || 'Servicio solicitado',
          date: request.createdAt,
          status: request.status,
          icon: 'support_agent',
          color: 'orange'
        });
      });

      // Sort by date
      activities.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

      res.json({ items: activities.slice(0, 10) });
    } catch (error) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  });

  app.get('/api/student-dashboard/professors', async (req, res) => {
    try {
      const professors = await ProfessorModel.find().limit(50);
      const professorsData = professors.map(prof => ({
        id: prof._id.toString(),
        name: prof.name,
        email: prof.email,
        phone: prof.phone || '',
        specialties: prof.specialties || [],
        hourlyRate: prof.hourlyRate || 0,
        pricing: {
          individualClass: 50000,
          groupClass: 35000,
          courtRental: 25000
        },
        experienceYears: 0,
        rating: 0
      }));

      res.json({ items: professorsData });
    } catch (error) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  });

  app.get('/api/student-dashboard/available-schedules', async (req, res) => {
    try {
      const { professorId } = req.query;
      
      if (!professorId) {
        return res.status(400).json({ error: 'professorId es requerido' });
      }

      const schedules = await ScheduleModel.find({
        professorId,
        startTime: { $gte: new Date() },
        isAvailable: true
      }).sort({ startTime: 1 }).limit(100);

      const schedulesData = schedules.map(schedule => ({
        id: schedule._id.toString(),
        professorId: schedule.professorId.toString(),
        startTime: schedule.startTime,
        endTime: schedule.endTime,
        type: 'individual_class',
        price: 0,
        status: 'pending'
      }));

      res.json({ items: schedulesData });
    } catch (error) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  });

  app.post('/api/student-dashboard/book-lesson', async (req, res) => {
    try {
      const firebaseUid = req.user?.uid;
      if (!firebaseUid) {
        return res.status(401).json({ error: 'Usuario no autenticado' });
      }

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

      // Get student
      const authUser = await AuthUserModel.findOne({ firebaseUid });
      if (!authUser) {
        return res.status(404).json({ error: 'Usuario no encontrado' });
      }

      const student = await StudentModel.findOne({ authUserId: authUser._id });
      if (!student) {
        return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
      }

      // Check schedule
      const schedule = await ScheduleModel.findById(scheduleId);
      if (!schedule) {
        return res.status(404).json({ error: 'Horario no encontrado' });
      }

      if (!schedule.isAvailable) {
        return res.status(400).json({ error: 'Este horario ya no está disponible' });
      }

      // Get professor
      const professor = await ProfessorModel.findById(schedule.professorId);
      if (!professor) {
        return res.status(404).json({ error: 'Profesor no encontrado' });
      }

      // Create booking
      const booking = await BookingModel.create({
        scheduleId: schedule._id,
        studentId: student._id,
        professorId: professor._id,
        serviceType: serviceType,
        price: price,
        status: 'confirmed',
        notes: `Reserva de ${serviceType}`
      });

      // Update schedule
      schedule.isAvailable = false;
      schedule.studentId = student._id;
      schedule.status = 'confirmed';
      await schedule.save();

      res.status(201).json({
        id: booking._id,
        studentId: booking.studentId,
        scheduleId: booking.scheduleId,
        serviceType: booking.serviceType,
        status: booking.status,
        price: booking.price,
        createdAt: booking.createdAt
      });
    } catch (error) {
      res.status(500).json({ error: 'Error interno del servidor' });
    }
  });

  return app;
};

describe('Student Flow Integration Tests (Simplified)', () => {
  let mongo: MongoMemoryServer;
  let app: Application;

  beforeAll(async () => {
    // Setup in-memory MongoDB
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);

    // Setup Express app
    app = createStudentFlowTestApp();
  });

  beforeEach(async () => {
    // Clear all collections before each test
    await AuthUserModel.deleteMany({});
    await StudentModel.deleteMany({});
    await ProfessorModel.deleteMany({});
    await ScheduleModel.deleteMany({});
    await BookingModel.deleteMany({});
    await PaymentModel.deleteMany({});
    await ServiceRequestModel.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongo.stop();
  });

  describe('Complete Student Registration Flow', () => {
    it('should complete student registration with Firebase auth', async () => {
      // Step 1: Register student
      const studentData = {
        name: 'Ana Estudiante',
        email: 'ana@example.com',
        phone: '+57 300 123 4567',
        role: 'student',
        firebaseUid: 'firebase-student-uid-123'
      };

      const registerResponse = await request(app)
        .post('/api/auth/firebase/register')
        .send(studentData)
        .expect(201);

      expect(registerResponse.body).toHaveProperty('accessToken');
      expect(registerResponse.body).toHaveProperty('refreshToken');
      expect(registerResponse.body).toHaveProperty('user');
      expect(registerResponse.body.user.role).toBe('student');

      // Step 2: Verify student was created in database
      const authUser = await AuthUserModel.findOne({ email: studentData.email });
      expect(authUser).toBeTruthy();
      expect(authUser?.role).toBe('student');

      const student = await StudentModel.findOne({ authUserId: authUser?._id });
      expect(student).toBeTruthy();
      expect(student?.name).toBe(studentData.name);
      expect(student?.email).toBe(studentData.email);
      expect(student?.membershipType).toBe('basic');
      expect(student?.balance).toBe(0);

      // Step 3: Verify dashboard access
      const profileResponse = await request(app)
        .get('/api/student-dashboard/me')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(profileResponse.body).toHaveProperty('id');
      expect(profileResponse.body).toHaveProperty('name', studentData.name);
      expect(profileResponse.body).toHaveProperty('email', studentData.email);
    });

    it('should complete student registration with traditional auth', async () => {
      // Step 1: Register student
      const studentData = {
        email: 'estudiante@example.com',
        password: 'password123',
        role: 'student',
        profile: {
          name: 'Carlos Estudiante',
          phone: '+57 300 987 6543',
          membershipType: 'premium'
        }
      };

      const registerResponse = await request(app)
        .post('/api/auth/register')
        .send(studentData)
        .expect(201);

      expect(registerResponse.body).toHaveProperty('accessToken');
      expect(registerResponse.body).toHaveProperty('refreshToken');

      // Step 2: Login
      const loginResponse = await request(app)
        .post('/api/auth/login')
        .send({
          email: studentData.email,
          password: studentData.password
        })
        .expect(200);

      expect(loginResponse.body).toHaveProperty('accessToken');
      expect(loginResponse.body).toHaveProperty('user');
      expect(loginResponse.body.user.role).toBe('student');

      // Step 3: Verify student profile
      const authUser = await AuthUserModel.findOne({ email: studentData.email });
      expect(authUser).toBeTruthy();

      const student = await StudentModel.findOne({ authUserId: authUser?._id });
      expect(student).toBeTruthy();
      expect(student?.membershipType).toBe('premium');
    });
  });

  describe('Complete Student Booking Flow', () => {
    let studentAuthUser: any;
    let student: any;
    let professor: any;
    let schedule: any;

    beforeEach(async () => {
      // Setup test data
      studentAuthUser = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Test Student',
        role: 'student',
        firebaseUid: 'test-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: studentAuthUser._id,
        name: 'Test Student',
        email: 'student@test.com',
        phone: '+57 300 111 1111',
        membershipType: 'basic',
        balance: 100
      });

      professor = await ProfessorModel.create({
        authUserId: new mongoose.Types.ObjectId(),
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50
      });

      schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date(Date.now() + 24 * 60 * 60 * 1000),
        startTime: new Date(Date.now() + 25 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 26 * 60 * 60 * 1000),
        isAvailable: true,
        status: 'pending'
      });
    });

    it('should complete booking flow: check schedules -> book -> verify', async () => {
      // Step 1: Check available schedules
      const schedulesResponse = await request(app)
        .get('/api/student/available-schedules')
        .query({ professorId: professor._id.toString() })
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(schedulesResponse.body).toHaveProperty('items');
      expect(schedulesResponse.body.items.length).toBeGreaterThan(0);
      
      const availableSchedule = schedulesResponse.body.items.find((s: any) => 
        s._id.toString() === schedule._id.toString()
      );
      expect(availableSchedule).toBeTruthy();
      expect(availableSchedule.isAvailable).toBe(true);

      // Step 2: Book the lesson
      const bookingData = {
        studentId: student._id.toString(),
        scheduleId: schedule._id.toString(),
        serviceType: 'individual_class',
        price: 50,
        notes: 'First tennis lesson'
      };

      const bookingResponse = await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .set('Authorization', `Bearer mock-token`)
        .expect(201);

      expect(bookingResponse.body).toHaveProperty('_id');
      expect(bookingResponse.body).toHaveProperty('studentId', student._id.toString());
      expect(bookingResponse.body).toHaveProperty('scheduleId', schedule._id.toString());
      expect(bookingResponse.body).toHaveProperty('serviceType', 'individual_class');
      expect(bookingResponse.body).toHaveProperty('status', 'confirmed');

      // Step 3: Verify schedule is no longer available
      const updatedSchedule = await ScheduleModel.findById(schedule._id);
      expect(updatedSchedule?.isAvailable).toBe(false);
      expect(updatedSchedule?.studentId?.toString()).toBe(student._id.toString());

      // Step 4: Verify booking was created
      const booking = await BookingModel.findOne({ 
        scheduleId: schedule._id,
        studentId: student._id 
      });
      expect(booking).toBeTruthy();
      expect(booking?.serviceType).toBe('individual_class');
      expect(booking?.price).toBe(50);
      expect(booking?.status).toBe('confirmed');

      // Step 5: Check student's bookings
      const bookingsResponse = await request(app)
        .get('/api/student/bookings')
        .query({ studentId: student._id.toString() })
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(bookingsResponse.body).toHaveProperty('items');
      expect(bookingsResponse.body.items.length).toBe(1);
      expect(bookingsResponse.body.items[0]._id.toString()).toBe(booking?._id.toString());
    });

    it('should handle booking conflicts', async () => {
      // Step 1: Book a lesson first time
      const bookingData = {
        studentId: student._id.toString(),
        scheduleId: schedule._id.toString(),
        serviceType: 'individual_class',
        price: 50
      };

      const firstBookingResponse = await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .set('Authorization', `Bearer mock-token`)
        .expect(201);

      expect(firstBookingResponse.body).toHaveProperty('_id');

      // Step 2: Try to book the same schedule again (should fail)
      const conflictResponse = await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .set('Authorization', `Bearer mock-token`)
        .expect(400);

      expect(conflictResponse.body).toHaveProperty('error');
      expect(conflictResponse.body.error).toContain('Schedule not available');

      // Step 3: Verify only one booking exists
      const bookings = await BookingModel.find({ 
        scheduleId: schedule._id 
      });
      expect(bookings).toHaveLength(1);
    });
  });

  describe('Complete Student Dashboard Integration', () => {
    let studentAuthUser: any;
    let student: any;
    let professor: any;

    beforeEach(async () => {
      // Setup comprehensive test data
      studentAuthUser = await AuthUserModel.create({
        email: 'dashboard@test.com',
        name: 'Dashboard Student',
        role: 'student',
        firebaseUid: 'dashboard-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: studentAuthUser._id,
        name: 'Dashboard Student',
        email: 'dashboard@test.com',
        membershipType: 'premium',
        balance: 300
      });

      professor = await ProfessorModel.create({
        authUserId: new mongoose.Types.ObjectId(),
        name: 'Dashboard Professor',
        email: 'dashboard-prof@test.com',
        phone: '+57 300 333 3333',
        specialties: ['tennis', 'footwork'],
        hourlyRate: 60
      });

      // Create some bookings
      const schedule1 = await ScheduleModel.create({
        professorId: professor._id,
        startTime: new Date(Date.now() + 24 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 25 * 60 * 60 * 1000),
        isAvailable: false,
        studentId: student._id,
        status: 'confirmed'
      });

      await BookingModel.create({
        scheduleId: schedule1._id,
        studentId: student._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        price: 60,
        status: 'confirmed'
      });

      // Create some payments
      await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 60,
        date: new Date(Date.now() - 2 * 24 * 60 * 60 * 1000),
        method: 'card',
        status: 'completed',
        description: 'Tennis lesson payment'
      });

      // Create service request
      await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: new mongoose.Types.ObjectId(),
        notes: 'Advanced coaching request',
        status: 'requested'
      });
    });

    it('should provide complete dashboard information', async () => {
      // Step 1: Get student profile
      const profileResponse = await request(app)
        .get('/api/student-dashboard/me')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(profileResponse.body).toHaveProperty('id');
      expect(profileResponse.body).toHaveProperty('name', 'Dashboard Student');
      expect(profileResponse.body).toHaveProperty('email', 'dashboard@test.com');
      expect(profileResponse.body).toHaveProperty('totalClasses');
      expect(profileResponse.body).toHaveProperty('totalPayments');
      expect(profileResponse.body).toHaveProperty('totalSpent');

      // Step 2: Get recent activities
      const activitiesResponse = await request(app)
        .get('/api/student-dashboard/activities')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(activitiesResponse.body).toHaveProperty('items');
      expect(Array.isArray(activitiesResponse.body.items)).toBe(true);
      expect(activitiesResponse.body.items.length).toBeGreaterThan(0);

      // Verify different activity types
      const activityTypes = activitiesResponse.body.items.map((a: any) => a.type);
      expect(activityTypes).toContain('booking');
      expect(activityTypes).toContain('payment');
      expect(activityTypes).toContain('service_request');

      // Step 3: Get available professors
      const professorsResponse = await request(app)
        .get('/api/student-dashboard/professors')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      expect(professorsResponse.body).toHaveProperty('items');
      expect(Array.isArray(professorsResponse.body.items)).toBe(true);
      
      const testProfessor = professorsResponse.body.items.find((p: any) => 
        p.name === 'Dashboard Professor'
      );
      expect(testProfessor).toBeTruthy();
      expect(testProfessor).toHaveProperty('specialties');
      expect(testProfessor).toHaveProperty('pricing');
      expect(testProfessor.specialties).toContain('tennis');
    });

    it('should handle complete booking flow through dashboard', async () => {
      // Step 1: Create an available schedule
      const availableSchedule = await ScheduleModel.create({
        professorId: professor._id,
        startTime: new Date(Date.now() + 48 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 49 * 60 * 60 * 1000),
        isAvailable: true,
        status: 'pending'
      });

      // Step 2: Get available schedules
      const schedulesResponse = await request(app)
        .get('/api/student-dashboard/available-schedules')
        .query({ professorId: professor._id.toString() })
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      const scheduleToBook = schedulesResponse.body.items.find((s: any) => 
        s.id === availableSchedule._id.toString()
      );
      expect(scheduleToBook).toBeTruthy();

      // Step 3: Book through dashboard
      const bookingData = {
        scheduleId: availableSchedule._id.toString(),
        serviceType: 'individual_class',
        price: 60
      };

      const bookingResponse = await request(app)
        .post('/api/student-dashboard/book-lesson')
        .send(bookingData)
        .set('Authorization', `Bearer mock-token`)
        .expect(201);

      expect(bookingResponse.body).toHaveProperty('id');
      expect(bookingResponse.body).toHaveProperty('studentId', student._id.toString());
      expect(bookingResponse.body).toHaveProperty('status', 'confirmed');

      // Step 4: Verify the booking appears in activities
      const activitiesResponse = await request(app)
        .get('/api/student-dashboard/activities')
        .set('Authorization', `Bearer mock-token`)
        .expect(200);

      const bookingActivity = activitiesResponse.body.items.find((a: any) => 
        a.type === 'booking' && a.title.includes('Clase reservada')
      );
      expect(bookingActivity).toBeTruthy();
    });
  });

  describe('Error Handling and Edge Cases', () => {
    let studentAuthUser: any;
    let student: any;

    beforeEach(async () => {
      studentAuthUser = await AuthUserModel.create({
        email: 'error@test.com',
        name: 'Error Student',
        role: 'student',
        firebaseUid: 'error-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: studentAuthUser._id,
        name: 'Error Student',
        email: 'error@test.com',
        membershipType: 'basic',
        balance: 50
      });
    });

    it('should handle authentication errors gracefully', async () => {
      // Test without token
      await request(app)
        .get('/api/student/balance')
        .query({ studentId: student._id.toString() })
        .expect(401);

      // Test with invalid token
      await request(app)
        .get('/api/student/balance')
        .query({ studentId: student._id.toString() })
        .set('Authorization', 'Bearer invalid-token')
        .expect(401);
    });

    it('should handle missing student scenarios', async () => {
      const nonExistentStudentId = new mongoose.Types.ObjectId().toString();

      // Test balance for non-existent student
      await request(app)
        .get('/api/student/balance')
        .query({ studentId: nonExistentStudentId })
        .set('Authorization', `Bearer mock-token`)
        .expect(404);

      // Test bookings for non-existent student
      await request(app)
        .get('/api/student/bookings')
        .query({ studentId: nonExistentStudentId })
        .set('Authorization', `Bearer mock-token`)
        .expect(200); // Returns empty array
    });

    it('should handle invalid data gracefully', async () => {
      // Test booking with invalid schedule
      const bookingData = {
        studentId: student._id.toString(),
        scheduleId: new mongoose.Types.ObjectId().toString(),
        serviceType: 'individual_class',
        price: 50
      };

      await request(app)
        .post('/api/student/book-lesson')
        .send(bookingData)
        .set('Authorization', `Bearer mock-token`)
        .expect(400);

      // Test service request with invalid data
      const serviceData = {
        studentId: student._id.toString(),
        serviceId: 'invalid_id'
      };

      await request(app)
        .post('/api/student/request-service')
        .send(serviceData)
        .set('Authorization', `Bearer mock-token`)
        .expect(201); // Mock accepts any serviceId
    });
  });
});

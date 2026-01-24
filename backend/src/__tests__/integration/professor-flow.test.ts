/**
 * Integration Tests for Professor Flow
 * TEN-73: TS-017: Testing de Integración - Professor Flow
 * 
 * Tests the complete professor journey including schedule management,
 * student interactions, income tracking, and dashboard operations
 */

import { describe, it, beforeEach, expect, jest } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose from 'mongoose';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { ServiceModel } from '../../infrastructure/database/models/ServiceModel';
import { MongoProfessorRepository, MongoStudentRepository, MongoScheduleRepository, MongoBookingRepository, MongoPaymentRepository, MongoServiceRepository } from '../../infrastructure/repositories/MongoRepositories';
import { ProfessorController } from '../../application/controllers/ProfessorController';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';

describe('Professor Flow Integration Tests', () => {
  let mongo: MongoMemoryServer;
  const commonTenantId = new mongoose.Types.ObjectId('660000000000000000000001');
  let professorRepository: MongoProfessorRepository;
  let studentRepository: MongoStudentRepository;
  let scheduleRepository: MongoScheduleRepository;
  let bookingRepository: MongoBookingRepository;
  let paymentRepository: MongoPaymentRepository;
  let serviceRepository: MongoServiceRepository;
  let professorController: ProfessorController;
  let professorDashboardController: ProfessorDashboardController;

  beforeAll(async () => {
    // Setup in-memory MongoDB
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);

    // Setup repositories and controllers
    professorRepository = new MongoProfessorRepository();
    studentRepository = new MongoStudentRepository();
    scheduleRepository = new MongoScheduleRepository();
    bookingRepository = new MongoBookingRepository();
    paymentRepository = new MongoPaymentRepository();
    serviceRepository = new MongoServiceRepository();
    professorController = new ProfessorController();
    professorDashboardController = new ProfessorDashboardController();
  });

  beforeEach(async () => {
    // Clear all collections before each test
    await AuthUserModel.deleteMany({});
    await StudentModel.deleteMany({});
    await ProfessorModel.deleteMany({});
    await ScheduleModel.deleteMany({});
    await BookingModel.deleteMany({});
    await PaymentModel.deleteMany({});
    await ServiceModel.deleteMany({});
  });

  afterAll(async () => {
    await mongoose.disconnect();
    await mongo.stop();
  });

  describe('Professor Registration and Profile Management', () => {
    let professorAuthUser: any;
    let professor: any;

    beforeEach(async () => {
      // Setup test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });
    });

    it('should create professor profile from auth user', async () => {
      // Verify professor was created correctly
      expect(professor).toBeTruthy();
      expect(professor.name).toBe('Test Professor');
      expect(professor.email).toBe('professor@test.com');
      expect(professor.specialties).toContain('tennis');
      expect(professor.hourlyRate).toBe(50);
      expect(professor.experienceYears).toBe(5);

      // Verify relationship with AuthUser
      const retrievedProfessor = await ProfessorModel.findOne({ authUserId: professorAuthUser._id });
      expect(retrievedProfessor).toBeTruthy();
      expect(retrievedProfessor?._id.toString()).toBe(professor._id.toString());
    });

    it('should update professor profile information', async () => {
      // Update professor profile
      const updatedProfessor = await ProfessorModel.findByIdAndUpdate(
        professor._id,
        {
          name: 'Updated Professor',
          phone: '+57 300 333 3333',
          specialties: ['tennis', 'fitness'],
          hourlyRate: 60,
          experienceYears: 7
        },
        { new: true }
      );

      expect(updatedProfessor).toBeTruthy();
      expect(updatedProfessor?.name).toBe('Updated Professor');
      expect(updatedProfessor?.phone).toBe('+57 300 333 3333');
      expect(updatedProfessor?.specialties).toHaveLength(2);
      expect(updatedProfessor?.specialties).toContain('tennis');
      expect(updatedProfessor?.specialties).toContain('fitness');
      expect(updatedProfessor?.hourlyRate).toBe(60);
      expect(updatedProfessor?.experienceYears).toBe(7);
    });

    it('should handle professor profile creation through dashboard', async () => {
      // Simulate dashboard controller behavior when professor doesn't exist
      const newAuthUser = await AuthUserModel.create({
        email: 'newprofessor@test.com',
        name: 'New Professor',
        role: 'professor',
        firebaseUid: 'new-professor-firebase-uid'
      });

      // Check if professor exists (should not)
      let existingProfessor = await ProfessorModel.findOne({ authUserId: newAuthUser._id });
      expect(existingProfessor).toBeNull();

      // Create professor profile (as dashboard controller would)
      const newProfessor = await ProfessorModel.create({
        authUserId: newAuthUser._id,
        name: newAuthUser.name || 'Profesor',
        email: newAuthUser.email,
        phone: '+57 300 000 0000', // Required field
        specialties: [],
        hourlyRate: 0,
        experienceYears: 0
      });

      expect(newProfessor).toBeTruthy();
      expect(newProfessor.name).toBe('New Professor');
      expect(newProfessor.email).toBe('newprofessor@test.com');
      expect(newProfessor.specialties).toHaveLength(0);
      expect(newProfessor.hourlyRate).toBe(0);
      expect(newProfessor.experienceYears).toBe(0);
    });
  });

  describe('Schedule Management Integration', () => {
    let professorAuthUser: any;
    let professor: any;

    beforeEach(async () => {
      // Setup test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });
    });

    it('should create and manage schedule availability', async () => {
      // Create a schedule
      const schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date('2025-01-15'),
        startTime: new Date('2025-01-15T10:00:00Z'),
        endTime: new Date('2025-01-15T11:00:00Z'),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });

      expect(schedule).toBeTruthy();
      expect(schedule.professorId.toString()).toBe(professor._id.toString());
      expect(schedule.isAvailable).toBe(true);
      expect(schedule.status).toBe('pending');

      // Update schedule availability
      const updatedSchedule = await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        { isAvailable: false, status: 'confirmed' },
        { new: true }
      );

      expect(updatedSchedule).toBeTruthy();
      expect(updatedSchedule?.isAvailable).toBe(false);
      expect(updatedSchedule?.status).toBe('confirmed');
    });

    it('should handle multiple schedules for same professor', async () => {
      const baseDate = new Date('2025-01-15');

      // Create multiple schedules
      const schedules = await Promise.all([
        ScheduleModel.create({
          professorId: professor._id,
          date: baseDate,
          startTime: new Date('2025-01-15T09:00:00Z'),
          endTime: new Date('2025-01-15T10:00:00Z'),
          isAvailable: true,
          status: 'pending'
        }),
        ScheduleModel.create({
          professorId: professor._id,
          date: baseDate,
          startTime: new Date('2025-01-15T10:00:00Z'),
          endTime: new Date('2025-01-15T11:00:00Z'),
          isAvailable: true,
          status: 'pending'
        }),
        ScheduleModel.create({
          professorId: professor._id,
          date: baseDate,
          startTime: new Date('2025-01-15T11:00:00Z'),
          endTime: new Date('2025-01-15T12:00:00Z'),
          isAvailable: false,
          status: 'confirmed'
        })
      ]);

      expect(schedules).toHaveLength(3);

      // Verify all schedules belong to same professor
      schedules.forEach(schedule => {
        expect(schedule.professorId.toString()).toBe(professor._id.toString());
      });

      // Find available schedules
      const availableSchedules = await ScheduleModel.find({
        professorId: professor._id,
        isAvailable: true
      });

      expect(availableSchedules).toHaveLength(2);

      // Find confirmed schedules
      const confirmedSchedules = await ScheduleModel.find({
        professorId: professor._id,
        status: 'confirmed'
      });

      expect(confirmedSchedules).toHaveLength(1);
    });

    it('should handle schedule deletion', async () => {
      // Create a schedule
      const schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date('2025-01-15'),
        startTime: new Date('2025-01-15T10:00:00Z'),
        endTime: new Date('2025-01-15T11:00:00Z'),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });

      expect(schedule).toBeTruthy();

      // Delete the schedule
      await ScheduleModel.findByIdAndDelete(schedule._id);

      // Verify schedule is deleted
      const deletedSchedule = await ScheduleModel.findById(schedule._id);
      expect(deletedSchedule).toBeNull();
    });
  });

  describe('Student-Professor Interaction Integration', () => {
    let professorAuthUser: any;
    let professor: any;
    let studentAuthUser: any;
    let student: any;
    let schedule: any;

    beforeEach(async () => {
      // Setup test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });

      studentAuthUser = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Test Student',
        role: 'student',
        firebaseUid: 'student-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: studentAuthUser._id,
        name: 'Test Student',
        email: 'student@test.com',
        phone: '+57 300 111 1111',
        membershipType: 'basic',
        balance: 100
      });

      schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date('2025-01-15'),
        startTime: new Date('2025-01-15T10:00:00Z'),
        endTime: new Date('2025-01-15T11:00:00Z'),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });
    });

    it('should handle student booking a professor schedule', async () => {
      // Student books the schedule
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id, // Required field
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50,
        notes: 'First tennis lesson',
        tenantId: commonTenantId
      });

      expect(booking).toBeTruthy();
      expect(booking.studentId.toString()).toBe(student._id.toString());
      expect(booking.scheduleId!.toString()).toBe(schedule._id.toString());
      expect(booking.serviceType).toBe('individual_class');
      expect(booking.status).toBe('confirmed');
      expect(booking.price).toBe(50);

      // Update schedule to reflect booking
      const updatedSchedule = await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        {
          isAvailable: false,
          studentId: student._id,
          status: 'confirmed'
        },
        { new: true }
      );

      expect(updatedSchedule).toBeTruthy();
      expect(updatedSchedule?.isAvailable).toBe(false);
      expect(updatedSchedule?.studentId?.toString()).toBe(student._id.toString());
      expect(updatedSchedule?.status).toBe('confirmed');
    });

    it('should track professor income from student payments', async () => {
      // Create a booking first
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50,
        notes: 'Tennis lesson payment',
        tenantId: commonTenantId
      });

      // Create payment record
      const payment = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        bookingId: booking._id,
        amount: 50,
        date: new Date(),
        status: 'paid',
        method: 'cash',
        description: 'Payment for tennis lesson',
        tenantId: commonTenantId
      });

      expect(payment).toBeTruthy();
      expect(payment.studentId.toString()).toBe(student._id.toString());
      expect(payment.professorId!.toString()).toBe(professor._id.toString());
      expect(payment.amount).toBe(50);
      expect(payment.status).toBe('paid');

      // Update student balance (payment reduces balance)
      const updatedStudent = await StudentModel.findByIdAndUpdate(
        student._id,
        { balance: student.balance - payment.amount },
        { new: true }
      );

      expect(updatedStudent).toBeTruthy();
      expect(updatedStudent?.balance).toBe(50); // 100 - 50
    });

    it('should handle class completion workflow', async () => {
      // Create booking
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50,
        notes: 'Tennis lesson'
      });

      // Update schedule with student
      await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        {
          isAvailable: false,
          studentId: student._id,
          status: 'confirmed'
        }
      );

      // Complete the class
      const completedSchedule = await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        { status: 'completed' },
        { new: true }
      );

      const completedBooking = await BookingModel.findByIdAndUpdate(
        booking._id,
        { status: 'completed' },
        { new: true }
      );

      expect(completedSchedule?.status).toBe('completed');
      expect(completedBooking?.status).toBe('completed');

      // Create payment for completed class
      const payment = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        bookingId: booking._id,
        amount: 50,
        date: new Date(),
        status: 'paid',
        method: 'cash',
        description: 'Payment for completed tennis lesson'
      });

      expect(payment).toBeTruthy();
      expect(payment.amount).toBe(50);
    });
  });

  describe('Service Management Integration', () => {
    let professorAuthUser: any;
    let professor: any;

    beforeEach(async () => {
      // Setup test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });
    });

    it('should create and manage services', async () => {
      // Create a service
      const service = await ServiceModel.create({
        name: 'Tennis Lesson Package',
        description: 'Package of 5 tennis lessons',
        price: 200,
        category: 'other'
      });

      expect(service).toBeTruthy();
      expect(service.name).toBe('Tennis Lesson Package');
      expect(service.price).toBe(200);
      expect(service.category).toBe('other');

      // Update service
      const updatedService = await ServiceModel.findByIdAndUpdate(
        service._id,
        {
          price: 250,
          description: 'Updated package of 5 tennis lessons with premium features'
        },
        { new: true }
      );

      expect(updatedService?.price).toBe(250);
      expect(updatedService?.description).toBe('Updated package of 5 tennis lessons with premium features');
    });

    it('should handle multiple services for professor', async () => {
      // Create multiple services
      const services = await Promise.all([
        ServiceModel.create({
          name: 'Individual Tennis Lesson',
          description: 'One-on-one tennis lesson',
          price: 50,
          category: 'other'
        }),
        ServiceModel.create({
          name: 'Group Tennis Lesson',
          description: 'Group tennis lesson for up to 4 students',
          price: 80,
          category: 'other'
        }),
        ServiceModel.create({
          name: 'Court Rental',
          description: 'Court rental without instructor',
          price: 30,
          category: 'other'
        })
      ]);

      expect(services).toHaveLength(3);

      // Find all services
      const allServices = await ServiceModel.find({});
      expect(allServices).toHaveLength(3);

      // Find services by category
      const otherServices = await ServiceModel.find({ category: 'other' });
      expect(otherServices).toHaveLength(3);
      expect(otherServices[0].name).toBe('Individual Tennis Lesson');
    });

    it('should update service pricing', async () => {
      // Create a service
      const service = await ServiceModel.create({
        name: 'Tennis Package',
        description: 'Tennis lesson package',
        price: 150,
        category: 'other'
      });

      expect(service.price).toBe(150);

      // Update service price
      const updatedService = await ServiceModel.findByIdAndUpdate(
        service._id,
        { price: 200 },
        { new: true }
      );

      expect(updatedService?.price).toBe(200);

      // Verify service was updated
      const foundService = await ServiceModel.findById(service._id);
      expect(foundService?.price).toBe(200);
    });
  });

  describe('Income and Analytics Integration', () => {
    let professorAuthUser: any;
    let professor: any;
    let studentAuthUser: any;
    let student: any;
    let schedule: any;

    beforeEach(async () => {
      // Setup test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });

      studentAuthUser = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Test Student',
        role: 'student',
        firebaseUid: 'student-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: studentAuthUser._id,
        name: 'Test Student',
        email: 'student@test.com',
        phone: '+57 300 111 1111',
        membershipType: 'basic',
        balance: 100
      });

      schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date('2025-01-15'),
        startTime: new Date('2025-01-15T10:00:00Z'),
        endTime: new Date('2025-01-15T11:00:00Z'),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });
    });

    it('should track monthly income for professor', async () => {
      // Create multiple payments for the month
      const payments = await Promise.all([
        PaymentModel.create({
          studentId: student._id,
          professorId: professor._id,
          amount: 50,
          date: new Date('2025-01-05'),
          status: 'paid',
          method: 'cash',
          description: 'January payment 1'
        }),
        PaymentModel.create({
          studentId: student._id,
          professorId: professor._id,
          amount: 50,
          date: new Date('2025-01-12'),
          status: 'paid',
          method: 'card',
          description: 'January payment 2'
        }),
        PaymentModel.create({
          studentId: student._id,
          professorId: professor._id,
          amount: 50,
          date: new Date('2025-01-19'),
          status: 'paid',
          method: 'transfer',
          description: 'January payment 3'
        })
      ]);

      expect(payments).toHaveLength(3);

      // Calculate monthly income
      const startOfMonth = new Date('2025-01-01');
      const endOfMonth = new Date('2025-01-31');

      const monthlyPayments = await PaymentModel.find({
        professorId: professor._id,
        date: { $gte: startOfMonth, $lte: endOfMonth },
        status: 'paid'
      });

      const monthlyIncome = monthlyPayments.reduce((sum, payment) => sum + payment.amount, 0);
      expect(monthlyIncome).toBe(150); // 50 + 50 + 50

      // Verify payment methods distribution
      const cashPayments = monthlyPayments.filter(p => p.method === 'cash');
      const cardPayments = monthlyPayments.filter(p => p.method === 'card');
      const transferPayments = monthlyPayments.filter(p => p.method === 'transfer');

      expect(cashPayments).toHaveLength(1);
      expect(cardPayments).toHaveLength(1);
      expect(transferPayments).toHaveLength(1);
    });

    it('should track weekly income for professor', async () => {
      // Create payments for current week
      const thisWeekStart = new Date('2025-01-13'); // Monday
      const thisWeekEnd = new Date('2025-01-19'); // Sunday

      const weeklyPayments = await Promise.all([
        PaymentModel.create({
          studentId: student._id,
          professorId: professor._id,
          amount: 50,
          date: new Date('2025-01-15'),
          status: 'paid',
          method: 'cash',
          description: 'Weekly payment 1'
        }),
        PaymentModel.create({
          studentId: student._id,
          professorId: professor._id,
          amount: 50,
          date: new Date('2025-01-17'),
          status: 'paid',
          method: 'card',
          description: 'Weekly payment 2'
        })
      ]);

      expect(weeklyPayments).toHaveLength(2);

      // Calculate weekly income
      const weekPayments = await PaymentModel.find({
        professorId: professor._id,
        date: { $gte: thisWeekStart, $lte: thisWeekEnd },
        status: 'paid'
      });

      const weeklyIncome = weekPayments.reduce((sum, payment) => sum + payment.amount, 0);
      expect(weeklyIncome).toBe(100); // 50 + 50
    });

    it('should track total earnings and classes completed', async () => {
      // Create completed classes with payments
      const completedClasses = await Promise.all([
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date('2025-01-01'),
          startTime: new Date('2025-01-01T10:00:00Z'),
          endTime: new Date('2025-01-01T11:00:00Z'),
          isAvailable: false,
          studentId: student._id,
          status: 'completed'
        }),
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date('2025-01-08'),
          startTime: new Date('2025-01-08T10:00:00Z'),
          endTime: new Date('2025-01-08T11:00:00Z'),
          isAvailable: false,
          studentId: student._id,
          status: 'completed'
        }),
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date('2025-01-15'),
          startTime: new Date('2025-01-15T10:00:00Z'),
          endTime: new Date('2025-01-15T11:00:00Z'),
          isAvailable: false,
          studentId: student._id,
          status: 'completed'
        })
      ]);

      // Create corresponding payments
      const payments = await Promise.all(
        completedClasses.map((schedule, index) =>
          PaymentModel.create({
            studentId: student._id,
            professorId: professor._id,
            amount: 50,
            date: schedule.date,
            status: 'paid',
            method: 'cash',
            description: `Payment for class ${index + 1}`
          })
        )
      );

      expect(completedClasses).toHaveLength(3);
      expect(payments).toHaveLength(3);

      // Calculate total earnings
      const totalPayments = await PaymentModel.find({
        professorId: professor._id,
        status: 'paid'
      });

      const totalEarnings = totalPayments.reduce((sum, payment) => sum + payment.amount, 0);
      expect(totalEarnings).toBe(150); // 50 * 3

      // Count completed classes
      const completedClassesCount = await ScheduleModel.countDocuments({
        professorId: professor._id,
        status: 'completed'
      });

      expect(completedClassesCount).toBe(3);
    });
  });

  describe('Complete Professor Workflow Integration', () => {
    let professorAuthUser: any;
    let professor: any;
    let studentAuthUser: any;
    let student: any;

    beforeEach(async () => {
      // Setup comprehensive test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });

      studentAuthUser = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Test Student',
        role: 'student',
        firebaseUid: 'student-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: studentAuthUser._id,
        name: 'Test Student',
        email: 'student@test.com',
        phone: '+57 300 111 1111',
        membershipType: 'basic',
        balance: 100
      });
    });

    it('should complete full professor workflow: setup -> schedule -> teach -> earn', async () => {
      // Step 1: Professor creates schedule
      const schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date('2025-01-15'),
        startTime: new Date('2025-01-15T10:00:00Z'),
        endTime: new Date('2025-01-15T11:00:00Z'),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });

      expect(schedule.isAvailable).toBe(true);
      expect(schedule.status).toBe('pending');

      // Step 2: Student books the schedule
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        status: 'confirmed',
        price: 50,
        notes: 'Tennis lesson booking'
      });

      // Update schedule to reflect booking
      const bookedSchedule = await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        {
          isAvailable: false,
          studentId: student._id,
          status: 'confirmed'
        },
        { new: true }
      );

      expect(bookedSchedule?.isAvailable).toBe(false);
      expect(bookedSchedule?.studentId?.toString()).toBe(student._id.toString());
      expect(bookedSchedule?.status).toBe('confirmed');

      // Step 3: Professor completes the class
      const completedSchedule = await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        { status: 'completed' },
        { new: true }
      );

      const completedBooking = await BookingModel.findByIdAndUpdate(
        booking._id,
        { status: 'completed' },
        { new: true }
      );

      expect(completedSchedule?.status).toBe('completed');
      expect(completedBooking?.status).toBe('completed');

      // Step 4: Payment is processed
      const payment = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        bookingId: booking._id,
        amount: 50,
        date: new Date(),
        status: 'paid',
        method: 'cash',
        description: 'Payment for completed tennis lesson'
      });

      // Update student balance
      const updatedStudent = await StudentModel.findByIdAndUpdate(
        student._id,
        { balance: student.balance - payment.amount },
        { new: true }
      );

      expect(payment.amount).toBe(50);
      expect(updatedStudent?.balance).toBe(50); // 100 - 50

      // Step 5: Professor tracks earnings
      const professorPayments = await PaymentModel.find({
        professorId: professor._id,
        status: 'paid'
      });

      const totalEarnings = professorPayments.reduce((sum, payment) => sum + payment.amount, 0);
      expect(totalEarnings).toBe(50);

      // Step 6: Professor updates profile with new experience
      const updatedProfessor = await ProfessorModel.findByIdAndUpdate(
        professor._id,
        { experienceYears: professor.experienceYears + 1 },
        { new: true }
      );

      expect(updatedProfessor?.experienceYears).toBe(6);

      // Step 7: Verify complete workflow data integrity
      const finalSchedule = await ScheduleModel.findById(schedule._id);
      const finalBooking = await BookingModel.findById(booking._id);
      const finalPayment = await PaymentModel.findById(payment._id);

      expect(finalSchedule?.status).toBe('completed');
      expect(finalBooking?.status).toBe('completed');
      expect(finalPayment?.status).toBe('paid');
      expect(finalSchedule?.studentId?.toString()).toBe(student._id.toString());
      expect(finalBooking?.studentId.toString()).toBe(student._id.toString());
      expect(finalPayment?.studentId.toString()).toBe(student._id.toString());
    });

    it('should handle professor managing multiple students and schedules', async () => {
      // Create additional students
      const student2AuthUser = await AuthUserModel.create({
        email: 'student2@test.com',
        name: 'Test Student 2',
        role: 'student',
        firebaseUid: 'student2-firebase-uid'
      });

      const student2 = await StudentModel.create({
        authUserId: student2AuthUser._id,
        name: 'Test Student 2',
        email: 'student2@test.com',
        phone: '+57 300 444 4444',
        membershipType: 'premium',
        balance: 200
      });

      // Create multiple schedules
      const schedules = await Promise.all([
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date('2025-01-15'),
          startTime: new Date('2025-01-15T09:00:00Z'),
          endTime: new Date('2025-01-15T10:00:00Z'),
          isAvailable: true,
          status: 'pending'
        }),
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date('2025-01-15'),
          startTime: new Date('2025-01-15T10:00:00Z'),
          endTime: new Date('2025-01-15T11:00:00Z'),
          isAvailable: true,
          status: 'pending'
        }),
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date('2025-01-15'),
          startTime: new Date('2025-01-15T11:00:00Z'),
          endTime: new Date('2025-01-15T12:00:00Z'),
          isAvailable: true,
          status: 'pending'
        })
      ]);

      // Students book different schedules
      const bookings = await Promise.all([
        BookingModel.create({
          studentId: student._id,
          scheduleId: schedules[0]._id,
          professorId: professor._id,
          serviceType: 'individual_class',
          status: 'confirmed',
          price: 50,
          notes: 'Student 1 booking'
        }),
        BookingModel.create({
          studentId: student2._id,
          scheduleId: schedules[1]._id,
          professorId: professor._id,
          serviceType: 'individual_class',
          status: 'confirmed',
          price: 50,
          notes: 'Student 2 booking'
        })
      ]);

      // Update schedules
      await Promise.all([
        ScheduleModel.findByIdAndUpdate(schedules[0]._id, {
          isAvailable: false,
          studentId: student._id,
          status: 'confirmed'
        }),
        ScheduleModel.findByIdAndUpdate(schedules[1]._id, {
          isAvailable: false,
          studentId: student2._id,
          status: 'confirmed'
        })
      ]);

      // Professor completes both classes
      await Promise.all([
        ScheduleModel.findByIdAndUpdate(schedules[0]._id, { status: 'completed' }),
        ScheduleModel.findByIdAndUpdate(schedules[1]._id, { status: 'completed' }),
        BookingModel.findByIdAndUpdate(bookings[0]._id, { status: 'completed' }),
        BookingModel.findByIdAndUpdate(bookings[1]._id, { status: 'completed' })
      ]);

      // Process payments
      const payments = await Promise.all([
        PaymentModel.create({
          studentId: student._id,
          professorId: professor._id,
          bookingId: bookings[0]._id,
          amount: 50,
          date: new Date(),
          status: 'paid',
          method: 'cash',
          description: 'Payment from student 1'
        }),
        PaymentModel.create({
          studentId: student2._id,
          professorId: professor._id,
          bookingId: bookings[1]._id,
          amount: 50,
          date: new Date(),
          status: 'paid',
          method: 'card',
          description: 'Payment from student 2'
        })
      ]);

      // Verify professor's total earnings
      const totalPayments = await PaymentModel.find({
        professorId: professor._id,
        status: 'paid'
      });

      const totalEarnings = totalPayments.reduce((sum, payment) => sum + payment.amount, 0);
      expect(totalEarnings).toBe(100); // 50 + 50

      // Verify professor's completed classes count
      const completedClasses = await ScheduleModel.countDocuments({
        professorId: professor._id,
        status: 'completed'
      });

      expect(completedClasses).toBe(2);

      // Verify one schedule remains available
      const availableSchedules = await ScheduleModel.countDocuments({
        professorId: professor._id,
        isAvailable: true
      });

      expect(availableSchedules).toBe(1);
    });
  });

  describe('Error Handling and Edge Cases', () => {
    let professorAuthUser: any;
    let professor: any;

    beforeEach(async () => {
      // Setup test data
      professorAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'professor-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: professorAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis'],
        hourlyRate: 50,
        experienceYears: 5
      });
    });

    it('should handle professor deletion cascade', async () => {
      // Create schedules and services for professor
      const schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date('2025-01-15'),
        startTime: new Date('2025-01-15T10:00:00Z'),
        endTime: new Date('2025-01-15T11:00:00Z'),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });

      const service = await ServiceModel.create({
        name: 'Tennis Lesson',
        description: 'Individual tennis lesson',
        price: 50,
        category: 'other'
      });

      // Verify data exists
      expect(schedule).toBeTruthy();
      expect(service).toBeTruthy();

      // Delete professor (in real scenario, this might cascade delete related data)
      await ProfessorModel.findByIdAndDelete(professor._id);
      await AuthUserModel.findByIdAndDelete(professorAuthUser._id);

      // Verify professor is deleted
      const deletedProfessor = await ProfessorModel.findById(professor._id);
      expect(deletedProfessor).toBeNull();

      // Verify related data still exists (cascade not implemented)
      const remainingSchedule = await ScheduleModel.findById(schedule._id);
      const remainingService = await ServiceModel.findById(service._id);

      expect(remainingSchedule).toBeTruthy();
      expect(remainingService).toBeTruthy();
    });

    it('should handle invalid schedule operations gracefully', async () => {
      // Try to update non-existent schedule
      const nonExistentId = new mongoose.Types.ObjectId();
      const result = await ScheduleModel.findByIdAndUpdate(
        nonExistentId,
        { isAvailable: false },
        { new: true }
      );

      expect(result).toBeNull();

      // Try to delete non-existent schedule
      const deleteResult = await ScheduleModel.findByIdAndDelete(nonExistentId);
      expect(deleteResult).toBeNull();
    });

    it('should maintain data integrity with concurrent operations', async () => {
      // Create multiple schedules simultaneously
      const schedulePromises = Array.from({ length: 5 }).map((_, index) =>
        ScheduleModel.create({
          professorId: professor._id,
          date: new Date(`2025-01-${15 + index}`),
          startTime: new Date(`2025-01-${15 + index}T10:00:00Z`),
          endTime: new Date(`2025-01-${15 + index}T11:00:00Z`),
          isAvailable: true,
          status: 'pending'
        })
      );

      const schedules = await Promise.all(schedulePromises);

      // Verify all schedules were created successfully
      expect(schedules).toHaveLength(5);

      // Verify all schedules belong to the same professor
      schedules.forEach(schedule => {
        expect(schedule.professorId.toString()).toBe(professor._id.toString());
      });

      // Verify professor has correct number of schedules
      const professorSchedules = await ScheduleModel.find({
        professorId: professor._id
      });

      expect(professorSchedules).toHaveLength(5);
    });
  });
});

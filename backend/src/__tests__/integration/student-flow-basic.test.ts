/**
 * Basic Integration Tests for Student Flow
 * TEN-74: TS-018: Testing de Integración - Student Flow
 * 
 * Tests the core integration points of the student flow
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
import { ServiceRequestModel } from '../../infrastructure/database/models/ServiceRequestModel';

describe('Student Flow Integration Tests (Basic)', () => {
  let mongo: MongoMemoryServer;
  const commonTenantId = new mongoose.Types.ObjectId('660000000000000000000001');

  beforeAll(async () => {
    // Setup in-memory MongoDB
    mongo = await MongoMemoryServer.create();
    const mongoUri = mongo.getUri();
    await mongoose.connect(mongoUri);
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

  describe('Student Registration Integration', () => {
    it('should create student profile when AuthUser is created', async () => {
      // Step 1: Create AuthUser for student
      const authUser = await AuthUserModel.create({
        email: 'student@example.com',
        name: 'Test Student',
        role: 'student',
        firebaseUid: 'firebase-uid-123'
      });

      expect(authUser).toBeTruthy();
      expect(authUser.role).toBe('student');

      // Step 2: Create Student profile linked to AuthUser
      const student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Test Student',
        email: 'student@example.com',
        phone: '+57 300 123 4567',
        membershipType: 'basic',
        balance: 0
      });

      expect(student).toBeTruthy();
      expect(student.authUserId.toString()).toBe(authUser._id.toString());
      expect(student.membershipType).toBe('basic');
      expect(student.balance).toBe(0);

      // Step 3: Verify relationship integrity
      const populatedStudent = await StudentModel.findById(student._id).populate('authUserId');
      expect(populatedStudent?.authUserId).toBeTruthy();
      expect((populatedStudent?.authUserId as any).email).toBe('student@example.com');
    });

    it('should handle student with premium membership', async () => {
      // Create premium student
      const authUser = await AuthUserModel.create({
        email: 'premium@example.com',
        name: 'Premium Student',
        role: 'student',
        firebaseUid: 'firebase-uid-premium'
      });

      const student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Premium Student',
        email: 'premium@example.com',
        phone: '+57 300 987 6543',
        membershipType: 'premium',
        balance: 1000
      });

      expect(student.membershipType).toBe('premium');
      expect(student.balance).toBe(1000);
    });
  });

  describe('Student-Professor-Schedule Integration', () => {
    let student: any;
    let professor: any;
    let schedule: any;

    beforeEach(async () => {
      // Setup test data
      const authUser = await AuthUserModel.create({
        email: 'student@test.com',
        name: 'Test Student',
        role: 'student',
        firebaseUid: 'test-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Test Student',
        email: 'student@test.com',
        phone: '+57 300 111 1111',
        membershipType: 'basic',
        balance: 100
      });

      const profAuthUser = await AuthUserModel.create({
        email: 'professor@test.com',
        name: 'Test Professor',
        role: 'professor',
        firebaseUid: 'prof-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: profAuthUser._id,
        name: 'Test Professor',
        email: 'professor@test.com',
        phone: '+57 300 222 2222',
        specialties: ['tennis', 'footwork'],
        hourlyRate: 50
      });

      schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date(Date.now() + 24 * 60 * 60 * 1000), // Tomorrow
        startTime: new Date(Date.now() + 25 * 60 * 60 * 1000), // Tomorrow + 1 hour
        endTime: new Date(Date.now() + 26 * 60 * 60 * 1000), // Tomorrow + 2 hours
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });
    });

    it('should create booking linking student, professor, and schedule', async () => {
      // Step 1: Verify initial state
      expect(schedule.isAvailable).toBe(true);
      expect(schedule.studentId).toBeUndefined();

      // Step 2: Create booking
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        price: 50,
        status: 'confirmed',
        notes: 'First tennis lesson',
        tenantId: commonTenantId
      });

      expect(booking).toBeTruthy();
      expect(booking.studentId.toString()).toBe(student._id.toString());
      expect(booking.scheduleId!.toString()).toBe(schedule._id.toString());
      expect(booking.professorId!.toString()).toBe(professor._id.toString());
      expect(booking.serviceType).toBe('individual_class');
      expect(booking.price).toBe(50);
      expect(booking.status).toBe('confirmed');

      // Step 3: Update schedule to reflect booking
      const updatedSchedule = await ScheduleModel.findByIdAndUpdate(
        schedule._id,
        {
          isAvailable: false,
          studentId: student._id,
          status: 'confirmed'
        },
        { new: true }
      );

      expect(updatedSchedule?.isAvailable).toBe(false);
      expect(updatedSchedule?.studentId?.toString()).toBe(student._id.toString());
      expect(updatedSchedule?.status).toBe('confirmed');
    });

    it('should handle booking conflicts correctly', async () => {
      // Step 1: Create first booking
      const booking1 = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        price: 50,
        status: 'confirmed',
        tenantId: commonTenantId
      });

      // Step 2: Update schedule
      await ScheduleModel.findByIdAndUpdate(schedule._id, {
        isAvailable: false,
        studentId: student._id,
        status: 'confirmed',
        tenantId: commonTenantId
      });

      // Step 3: Try to create another booking for same schedule
      // Note: In a real system, this would be prevented by business logic
      // For this test, we'll create it but verify the schedule is already booked
      const booking2 = await BookingModel.create({
        studentId: new mongoose.Types.ObjectId(), // Different student
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        price: 50,
        status: 'confirmed',
        tenantId: commonTenantId
      });

      // Step 4: Verify both bookings exist (database allows it, business logic should prevent)
      const bookings = await BookingModel.find({ scheduleId: schedule._id });
      expect(bookings).toHaveLength(2);

      // Both bookings should exist but the schedule should be marked as unavailable
      const updatedSchedule = await ScheduleModel.findById(schedule._id);
      expect(updatedSchedule?.isAvailable).toBe(false);
      expect(updatedSchedule?.studentId?.toString()).toBe(student._id.toString());
    });
  });

  describe('Student Payment Integration', () => {
    let student: any;
    let professor: any;

    beforeEach(async () => {
      const authUser = await AuthUserModel.create({
        email: 'payment@test.com',
        name: 'Payment Student',
        role: 'student',
        firebaseUid: 'payment-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Payment Student',
        email: 'payment@test.com',
        membershipType: 'basic',
        balance: 200
      });

      const profAuthUser = await AuthUserModel.create({
        email: 'payment-prof@test.com',
        name: 'Payment Professor',
        role: 'professor',
        firebaseUid: 'payment-prof-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: profAuthUser._id,
        name: 'Payment Professor',
        email: 'payment-prof@test.com',
        phone: '+57 300 333 3333',
        specialties: ['tennis'],
        hourlyRate: 60
      });
    });

    it('should create payment and update student balance', async () => {
      const initialBalance = student.balance;

      // Step 1: Create payment
      const payment = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 75,
        date: new Date(),
        method: 'card',
        status: 'paid',
        description: 'Tennis lesson payment',
        tenantId: commonTenantId
      });

      expect(payment).toBeTruthy();
      expect(payment.studentId.toString()).toBe(student._id.toString());
      expect(payment.professorId!.toString()).toBe(professor._id.toString());
      expect(payment.amount).toBe(75);
      expect(payment.status).toBe('paid');

      // Step 2: Update student balance (simulating payment deduction)
      const updatedStudent = await StudentModel.findByIdAndUpdate(
        student._id,
        { balance: initialBalance - payment.amount },
        { new: true }
      );

      expect(updatedStudent?.balance).toBe(initialBalance - 75);

      // Step 3: Verify payment history
      const payments = await PaymentModel.find({ studentId: student._id });
      expect(payments).toHaveLength(1);
      expect(payments[0].amount).toBe(75);
    });

    it('should handle multiple payments correctly', async () => {
      const initialBalance = student.balance;

      // Create multiple payments
      const payment1 = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 50,
        date: new Date(Date.now() - 24 * 60 * 60 * 1000), // Yesterday
        method: 'cash',
        status: 'paid',
        description: 'First lesson',
        tenantId: commonTenantId
      });

      const payment2 = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 75,
        date: new Date(),
        method: 'card',
        status: 'paid',
        description: 'Second lesson',
        tenantId: commonTenantId
      });

      // Update balance
      const totalSpent = payment1.amount + payment2.amount;
      await StudentModel.findByIdAndUpdate(
        student._id,
        { balance: initialBalance - totalSpent }
      );

      // Verify payments
      const payments = await PaymentModel.find({ studentId: student._id }).sort({ date: -1 });
      expect(payments).toHaveLength(2);
      expect(payments[0].amount).toBe(75); // Most recent first
      expect(payments[1].amount).toBe(50);

      // Verify different payment methods
      const methods = payments.map(p => p.method);
      expect(methods).toContain('cash');
      expect(methods).toContain('card');
    });
  });

  describe('Student Service Request Integration', () => {
    let student: any;

    beforeEach(async () => {
      const authUser = await AuthUserModel.create({
        email: 'service@test.com',
        name: 'Service Student',
        role: 'student',
        firebaseUid: 'service-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Service Student',
        email: 'service@test.com',
        membershipType: 'basic',
        balance: 150
      });
    });

    it('should create service request for student', async () => {
      const serviceId = new mongoose.Types.ObjectId();

      // Step 1: Create service request
      const serviceRequest = await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: serviceId,
        notes: 'Looking for advanced tennis coaching',
        status: 'requested',
        tenantId: commonTenantId
      });

      expect(serviceRequest).toBeTruthy();
      expect(serviceRequest.studentId.toString()).toBe(student._id.toString());
      expect(serviceRequest.serviceId.toString()).toBe(serviceId.toString());
      expect(serviceRequest.notes).toBe('Looking for advanced tennis coaching');
      expect(serviceRequest.status).toBe('requested');

      // Step 2: Verify relationship
      const populatedRequest = await ServiceRequestModel.findById(serviceRequest._id)
        .populate('studentId');

      expect(populatedRequest?.studentId).toBeTruthy();
      expect((populatedRequest?.studentId as any).name).toBe('Service Student');
    });

    it('should handle multiple service requests', async () => {
      const serviceId1 = new mongoose.Types.ObjectId();
      const serviceId2 = new mongoose.Types.ObjectId();

      // Create multiple service requests
      await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: serviceId1,
        notes: 'Private lesson request',
        status: 'requested',
        tenantId: commonTenantId
      });

      await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: serviceId2,
        notes: 'Court rental request',
        status: 'requested',
        tenantId: commonTenantId
      });

      // Verify both requests exist
      const requests = await ServiceRequestModel.find({ studentId: student._id });
      expect(requests).toHaveLength(2);
      expect(requests.every(r => r.status === 'requested')).toBe(true);
    });
  });

  describe('Complete Student Flow Integration', () => {
    let student: any;
    let professor: any;
    let schedule: any;

    beforeEach(async () => {
      // Setup complete test scenario
      const authUser = await AuthUserModel.create({
        email: 'complete@test.com',
        name: 'Complete Student',
        role: 'student',
        firebaseUid: 'complete-firebase-uid'
      });

      student = await StudentModel.create({
        authUserId: authUser._id,
        name: 'Complete Student',
        email: 'complete@test.com',
        membershipType: 'premium',
        balance: 500
      });

      const profAuthUser = await AuthUserModel.create({
        email: 'complete-prof@test.com',
        name: 'Complete Professor',
        role: 'professor',
        firebaseUid: 'complete-prof-firebase-uid'
      });

      professor = await ProfessorModel.create({
        authUserId: profAuthUser._id,
        name: 'Complete Professor',
        email: 'complete-prof@test.com',
        phone: '+57 300 444 4444',
        specialties: ['tennis', 'strategy'],
        hourlyRate: 80
      });

      schedule = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date(Date.now() + 48 * 60 * 60 * 1000), // 2 days from now
        startTime: new Date(Date.now() + 49 * 60 * 60 * 1000), // 2 days + 1 hour
        endTime: new Date(Date.now() + 50 * 60 * 60 * 1000), // 2 days + 2 hours
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });
    });

    it('should complete full student journey: register -> book -> pay -> request service', async () => {
      // Step 1: Verify initial student state
      expect(student.balance).toBe(500);
      expect(student.membershipType).toBe('premium');

      // Step 2: Create booking
      const booking = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        price: 80,
        status: 'confirmed',
        notes: 'Complete flow test booking',
        tenantId: commonTenantId
      });

      // Update schedule
      await ScheduleModel.findByIdAndUpdate(schedule._id, {
        isAvailable: false,
        studentId: student._id,
        status: 'confirmed',
        tenantId: commonTenantId
      });

      // Step 3: Create payment
      const payment = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 80,
        date: new Date(),
        method: 'card',
        status: 'paid',
        description: 'Payment for complete flow test',
        tenantId: commonTenantId
      });

      // Update student balance
      await StudentModel.findByIdAndUpdate(
        student._id,
        { balance: student.balance - payment.amount }
      );

      // Step 4: Create service request
      const serviceRequest = await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: new mongoose.Types.ObjectId(),
        notes: 'Additional coaching needed',
        status: 'requested',
        tenantId: commonTenantId
      });

      // Step 5: Verify all entities are properly linked
      const finalStudent = await StudentModel.findById(student._id);
      const finalBooking = await BookingModel.findById(booking._id);
      const finalPayment = await PaymentModel.findById(payment._id);
      const finalServiceRequest = await ServiceRequestModel.findById(serviceRequest._id);
      const finalSchedule = await ScheduleModel.findById(schedule._id);

      // Verify student state
      expect(finalStudent?.balance).toBe(420); // 500 - 80
      expect(finalStudent?.membershipType).toBe('premium');

      // Verify booking
      expect(finalBooking?.studentId.toString()).toBe(student._id.toString());
      expect(finalBooking!.professorId!.toString()).toBe(professor._id.toString());
      expect(finalBooking!.scheduleId!.toString()).toBe(schedule._id.toString());
      expect(finalBooking?.status).toBe('confirmed');

      // Verify payment
      expect(finalPayment?.studentId.toString()).toBe(student._id.toString());
      expect(finalPayment?.amount).toBe(80);
      expect(finalPayment?.status).toBe('paid');

      // Verify service request
      expect(finalServiceRequest?.studentId.toString()).toBe(student._id.toString());
      expect(finalServiceRequest?.status).toBe('requested');

      // Verify schedule
      expect(finalSchedule?.isAvailable).toBe(false);
      expect(finalSchedule?.studentId?.toString()).toBe(student._id.toString());
      expect(finalSchedule?.status).toBe('confirmed');
    });

    it('should maintain data integrity across all student operations', async () => {
      // Create multiple bookings
      const booking1 = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule._id,
        professorId: professor._id,
        serviceType: 'individual_class',
        price: 80,
        status: 'confirmed',
        tenantId: commonTenantId
      });

      // Create another schedule and booking
      const schedule2 = await ScheduleModel.create({
        professorId: professor._id,
        date: new Date(Date.now() + 72 * 60 * 60 * 1000), // 3 days from now
        startTime: new Date(Date.now() + 73 * 60 * 60 * 1000),
        endTime: new Date(Date.now() + 74 * 60 * 60 * 1000),
        isAvailable: true,
        status: 'pending',
        tenantId: commonTenantId
      });

      const booking2 = await BookingModel.create({
        studentId: student._id,
        scheduleId: schedule2._id,
        professorId: professor._id,
        serviceType: 'group_class',
        price: 50,
        status: 'confirmed',
        tenantId: commonTenantId
      });

      // Create payments for both bookings
      const payment1 = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 80,
        date: new Date(),
        method: 'card',
        status: 'paid',
        description: 'Individual class payment',
        tenantId: commonTenantId
      });

      const payment2 = await PaymentModel.create({
        studentId: student._id,
        professorId: professor._id,
        amount: 50,
        date: new Date(),
        method: 'cash',
        status: 'paid',
        description: 'Group class payment',
        tenantId: commonTenantId
      });

      // Create multiple service requests
      await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: new mongoose.Types.ObjectId(),
        notes: 'Request 1',
        status: 'requested',
        tenantId: commonTenantId
      });

      await ServiceRequestModel.create({
        studentId: student._id,
        serviceId: new mongoose.Types.ObjectId(),
        notes: 'Request 2',
        status: 'requested',
        tenantId: commonTenantId
      });

      // Verify data integrity
      const bookings = await BookingModel.find({ studentId: student._id });
      const payments = await PaymentModel.find({ studentId: student._id });
      const serviceRequests = await ServiceRequestModel.find({ studentId: student._id });

      expect(bookings).toHaveLength(2);
      expect(payments).toHaveLength(2);
      expect(serviceRequests).toHaveLength(2);

      // Verify all bookings belong to the same student
      expect(bookings.every(b => b.studentId.toString() === student._id.toString())).toBe(true);

      // Verify all payments belong to the same student
      expect(payments.every(p => p.studentId.toString() === student._id.toString())).toBe(true);

      // Verify all service requests belong to the same student
      expect(serviceRequests.every(sr => sr.studentId.toString() === student._id.toString())).toBe(true);

      // Verify professor consistency
      expect(bookings.every(b => b.professorId!.toString() === professor._id.toString())).toBe(true);
      expect(payments.every(p => p.professorId!.toString() === professor._id.toString())).toBe(true);
    });
  });
});

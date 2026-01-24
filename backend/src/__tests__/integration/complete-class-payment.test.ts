import { describe, it, beforeAll, afterAll, afterEach, expect } from '@jest/globals';
import request from 'supertest';
import mongoose from 'mongoose';
import express, { Application } from 'express';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';

/**
 * Integration test for completeClass payment logic
 * 
 * Verifies that:
 * 1. No duplicate payment is created if one already exists (e.g., from Wompi)
 * 2. A new payment is created if none exists
 * 3. No payment is created if no amount is provided
 */
describe('ProfessorDashboardController - completeClass Payment Logic', () => {
    let mongo: MongoMemoryServer;
    let app: Application;
    const commonTenantId = new mongoose.Types.ObjectId();
    let professorAuthUser: any;
    let professor: any;
    let studentAuthUser: any;
    let student: any;
    let professorDashboardController: ProfessorDashboardController;

    beforeAll(async () => {
        // Start in-memory MongoDB
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        await mongoose.connect(mongoUri);

        professorDashboardController = new ProfessorDashboardController();

        app = express();
        app.use(express.json());

        // Mock middleware to inject tenantId and user
        const mockAuth = (req: any, res: any, next: any) => {
            req.tenantId = commonTenantId.toString();
            req.user = { uid: 'test-professor-uid', role: 'professor' };
            next();
        };

        // Routes
        app.put('/api/professor-dashboard/schedule/:scheduleId/complete', mockAuth, professorDashboardController.completeClass);

        // Create professor auth user and profile
        professorAuthUser = await AuthUserModel.create({
            firebaseUid: 'test-professor-uid',
            email: 'professor@test.com',
            role: 'professor',
            tenantId: commonTenantId,
        });

        professor = await ProfessorModel.create({
            authUserId: professorAuthUser._id,
            name: 'Test Professor',
            email: 'professor@test.com',
            phone: '1234567890',
            hourlyRate: 50000,
            tenantId: commonTenantId,
        });

        // Create student auth user and profile
        studentAuthUser = await AuthUserModel.create({
            firebaseUid: 'test-student-uid',
            email: 'student@test.com',
            role: 'student',
            tenantId: commonTenantId,
        });

        student = await StudentModel.create({
            authUserId: studentAuthUser._id,
            name: 'Test Student',
            email: 'student@test.com',
            phone: '0987654321',
            membershipType: 'basic',
            tenantId: commonTenantId,
        });
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    afterEach(async () => {
        await ScheduleModel.deleteMany({});
        await BookingModel.deleteMany({});
        await PaymentModel.deleteMany({});
    });

    it('should NOT create duplicate payment if one already exists (e.g., from Wompi)', async () => {
        // 1. Create a schedule
        const schedule = await ScheduleModel.create({
            professorId: professor._id,
            studentId: student._id,
            startTime: new Date('2024-01-15T10:00:00Z'),
            endTime: new Date('2024-01-15T11:00:00Z'),
            status: 'confirmed',
            date: new Date('2024-01-15'),
            tenantId: commonTenantId,
        });

        // 2. Create a booking
        const booking = await BookingModel.create({
            scheduleId: schedule._id,
            studentId: student._id,
            professorId: professor._id,
            serviceType: 'individual_class',
            status: 'confirmed',
            price: 50000,
            tenantId: commonTenantId,
        });

        // 3. Simulate an existing payment (e.g., from Wompi)
        const existingPayment = await PaymentModel.create({
            studentId: student._id,
            professorId: professor._id,
            bookingId: booking._id,
            tenantId: commonTenantId,
            amount: 50000,
            date: new Date(),
            status: 'paid',
            method: 'transfer',
            description: 'Pago realizado por Wompi',
        });

        // 4. Complete the class with a payment amount
        const response = await request(app)
            .put(`/api/professor-dashboard/schedule/${schedule._id}/complete`)
            .send({
                paymentAmount: 50000,
                paymentStatus: 'paid',
            });

        // 5. Verify response
        expect(response.status).toBe(200);
        expect(response.body.paymentId).toBe(existingPayment._id.toString());
        expect(response.body.paymentAlreadyExists).toBe(true);

        // 6. Verify no duplicate payment was created
        const payments = await PaymentModel.find({ bookingId: booking._id });
        expect(payments).toHaveLength(1);
        expect(payments[0]!._id.toString()).toBe(existingPayment._id.toString());
    });

    it('should create a new payment if none exists', async () => {
        // 1. Create a schedule
        const schedule = await ScheduleModel.create({
            professorId: professor._id,
            studentId: student._id,
            startTime: new Date('2024-01-15T10:00:00Z'),
            endTime: new Date('2024-01-15T11:00:00Z'),
            status: 'confirmed',
            date: new Date('2024-01-15'),
            tenantId: commonTenantId,
        });

        // 2. Create a booking
        const booking = await BookingModel.create({
            scheduleId: schedule._id,
            studentId: student._id,
            professorId: professor._id,
            serviceType: 'individual_class',
            status: 'confirmed',
            price: 50000,
            tenantId: commonTenantId,
        });

        // 3. Complete the class with a payment amount (no existing payment)
        const response = await request(app)
            .put(`/api/professor-dashboard/schedule/${schedule._id}/complete`)
            .send({
                paymentAmount: 50000,
                paymentStatus: 'paid',
            });

        // 4. Verify response
        expect(response.status).toBe(200);
        expect(response.body.paymentId).toBeDefined();
        expect(response.body.paymentAlreadyExists).toBe(false);

        // 5. Verify a new payment was created
        const payments = await PaymentModel.find({ bookingId: booking._id });
        expect(payments).toHaveLength(1);
        expect(payments[0]!.amount).toBe(50000);
        expect(payments[0]!.status).toBe('paid');
        expect(payments[0]!.method).toBe('cash');
    });

    it('should NOT create a payment if no amount is provided', async () => {
        // 1. Create a schedule
        const schedule = await ScheduleModel.create({
            professorId: professor._id,
            studentId: student._id,
            startTime: new Date('2024-01-15T10:00:00Z'),
            endTime: new Date('2024-01-15T11:00:00Z'),
            status: 'confirmed',
            date: new Date('2024-01-15'),
            tenantId: commonTenantId,
        });

        // 2. Create a booking
        const booking = await BookingModel.create({
            scheduleId: schedule._id,
            studentId: student._id,
            professorId: professor._id,
            serviceType: 'individual_class',
            status: 'confirmed',
            price: 50000,
            tenantId: commonTenantId,
        });

        // 3. Complete the class WITHOUT a payment amount
        const response = await request(app)
            .put(`/api/professor-dashboard/schedule/${schedule._id}/complete`)
            .send({});

        // 4. Verify response
        expect(response.status).toBe(200);
        expect(response.body.paymentId).toBeUndefined();

        // 5. Verify no payment was created
        const payments = await PaymentModel.find({ bookingId: booking._id });
        expect(payments).toHaveLength(0);
    });
});

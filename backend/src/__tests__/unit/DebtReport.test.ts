import { describe, it, beforeEach, expect, jest, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Types } from 'mongoose';
import { TenantAdminController } from '../../application/controllers/TenantAdminController';
import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { TenantService } from '../../application/services/TenantService';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { Request, Response } from 'express';

describe('Debt and Payment Reports', () => {
    let mongo: MongoMemoryServer;
    let adminController: TenantAdminController;
    let studentController: StudentDashboardController;
    let tenantId: string;
    let studentId: string;
    let mockRequest: any;
    let mockResponse: any;

    beforeAll(async () => {
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        await mongoose.connect(mongoUri);
        adminController = new TenantAdminController(new TenantService());
        studentController = new StudentDashboardController();
    });

    beforeEach(async () => {
        await AuthUserModel.deleteMany({});
        await StudentModel.deleteMany({});
        await StudentTenantModel.deleteMany({});
        await PaymentModel.deleteMany({});

        tenantId = new Types.ObjectId().toString();

        // Create student
        const authUser = await AuthUserModel.create({
            email: 'student@test.com',
            name: 'Test Student',
            role: 'student',
            firebaseUid: 'fb-123',
        });
        const student = await StudentModel.create({
            authUserId: authUser._id,
            name: 'Test Student',
            email: 'student@test.com',
            membershipType: 'basic',
        });
        studentId = student._id.toString();

        mockResponse = {
            status: jest.fn().mockReturnThis(),
            json: jest.fn().mockReturnThis(),
        };
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    describe('TenantAdminController.getDebtReport', () => {
        it('should return report with negative balances and pending payments', async () => {
            // 1. Create a student with negative balance
            await StudentTenantModel.create({
                studentId: new Types.ObjectId(studentId),
                tenantId: new Types.ObjectId(tenantId),
                balance: -50000,
                isActive: true,
            });

            // 2. Create another student with pending payment
            const student2 = await StudentModel.create({
                authUserId: new Types.ObjectId(),
                name: 'Pending Student',
                email: 'pending@test.com',
                membershipType: 'basic',
            });
            await StudentTenantModel.create({
                studentId: student2._id,
                tenantId: new Types.ObjectId(tenantId),
                balance: 0,
                isActive: true,
            });
            await PaymentModel.create({
                studentId: student2._id,
                tenantId: new Types.ObjectId(tenantId),
                amount: 30000,
                status: 'pending',
                method: 'transfer',
                date: new Date(),
            });

            const req = { tenantId, query: {} } as any;

            await adminController.getDebtReport(req as Request, mockResponse as Response);

            expect(mockResponse.json).toHaveBeenCalled();
            const report = mockResponse.json.mock.calls[0][0];

            expect(report.summary.totalDebt).toBe(50000); // Solo balance negativo, no incluye pending payments
            expect(report.summary.debtByBalance).toBe(50000);
            expect(report.summary.debtByPendingPayments).toBe(30000);
            expect(report.summary.debtorCount).toBe(2);
            expect(report.debtors).toHaveLength(2);
        });
    });

    describe('StudentDashboardController.getPaymentHistory', () => {
        it('should return paginated payment history for the student', async () => {
            // Create some payments
            await PaymentModel.create([
                {
                    studentId: new Types.ObjectId(studentId),
                    tenantId: new Types.ObjectId(tenantId),
                    amount: 50000,
                    status: 'paid',
                    method: 'transfer',
                    date: new Date('2024-01-01'),
                    description: 'Payment 1',
                },
                {
                    studentId: new Types.ObjectId(studentId),
                    tenantId: new Types.ObjectId(tenantId),
                    amount: 30000,
                    status: 'pending',
                    method: 'transfer',
                    date: new Date('2024-01-10'),
                    description: 'Payment 2',
                }
            ]);

            const req = {
                user: { uid: 'fb-123' },
                tenantId,
                query: {}
            } as any;

            await studentController.getPaymentHistory(req as any, mockResponse as Response);

            expect(mockResponse.json).toHaveBeenCalled();
            const data = mockResponse.json.mock.calls[0][0];
            expect(data.items).toHaveLength(2);
            expect(data.items[0].amount).toBe(30000); // Sorted by date desc
        });

        it('should filter by status', async () => {
            await PaymentModel.create([
                {
                    studentId: new Types.ObjectId(studentId),
                    tenantId: new Types.ObjectId(tenantId),
                    amount: 50000,
                    status: 'paid',
                    method: 'transfer',
                    date: new Date(),
                },
                {
                    studentId: new Types.ObjectId(studentId),
                    tenantId: new Types.ObjectId(tenantId),
                    amount: 30000,
                    status: 'pending',
                    method: 'transfer',
                    date: new Date(),
                }
            ]);

            const req = {
                user: { uid: 'fb-123' },
                tenantId,
                query: { status: 'paid' }
            } as any;

            await studentController.getPaymentHistory(req as any, mockResponse as Response);

            const data = mockResponse.json.mock.calls[0][0];
            expect(data.items).toHaveLength(1);
            expect(data.items[0].status).toBe('paid');
        });
    });
});

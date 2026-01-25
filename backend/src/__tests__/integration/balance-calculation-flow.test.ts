/**
 * Integration Test: Balance Calculation Flow
 * 
 * Tests the complete balance calculation flow including:
 * 1. Wompi recharge (creates Payment without bookingId)
 * 2. Booking creation with sufficient balance (creates Payment with bookingId, method: 'wallet')
 * 3. Balance calculation using BalanceService
 * 4. Admin confirming payment (should not duplicate balance)
 * 5. Professor completing class (should not add balance if payment is with wallet)
 * 
 * This test validates that:
 * - Balance is correctly calculated from Payments and Bookings
 * - Payments with method 'wallet' don't add balance when confirmed
 * - No duplicate payments are created
 * - StudentTenant.balance field is kept in sync
 */

import { describe, it, beforeAll, afterAll, beforeEach, expect } from '@jest/globals';
import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { Types } from 'mongoose';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BalanceService } from '../../application/services/BalanceService';
import { BookingService } from '../../application/services/BookingService';
import { TenantService } from '../../application/services/TenantService';
import { TenantAdminController } from '../../application/controllers/TenantAdminController';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';
import { Request, Response } from 'express';

describe('Balance Calculation Flow Integration Tests', () => {
    let mongo: MongoMemoryServer;
    let balanceService: BalanceService;
    let bookingService: BookingService;
    let tenantAdminController: TenantAdminController;
    let professorDashboardController: ProfessorDashboardController;
    
    const tenantId = new Types.ObjectId();
    let student: any;
    let professor: any;
    let court: any;
    let tenant: any;

    beforeAll(async () => {
        // Setup in-memory MongoDB
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        await mongoose.connect(mongoUri);

        // Initialize services
        balanceService = new BalanceService();
        bookingService = new BookingService();
        const tenantService = new TenantService();
        tenantAdminController = new TenantAdminController(tenantService);
        professorDashboardController = new ProfessorDashboardController();
    });

    beforeEach(async () => {
        // Clear all collections
        await AuthUserModel.deleteMany({});
        await StudentModel.deleteMany({});
        await ProfessorModel.deleteMany({});
        await TenantModel.deleteMany({});
        await CourtModel.deleteMany({});
        await BookingModel.deleteMany({});
        await PaymentModel.deleteMany({});
        await StudentTenantModel.deleteMany({});
        await ScheduleModel.deleteMany({});

        // Create tenant with online payments enabled
        const tenantAdmin = await AuthUserModel.create({
            firebaseUid: 'tenant-admin-uid',
            email: 'admin@tenant.com',
            role: 'tenant_admin',
            tenantId: tenantId,
        });

        tenant = await TenantModel.create({
            name: 'Test Tennis Club',
            slug: 'test-club',
            adminUserId: tenantAdmin._id,
            config: {
                payments: {
                    enableOnlinePayments: true,
                    activeProvider: 'wompi',
                    wompi: {
                        pubKey: 'pub_test_123',
                        eventsKey: 'events_test_123',
                        integrityKey: 'integrity_test_123',
                        isTest: true,
                    },
                },
                basePricing: {
                    individualClass: 50000,
                    courtRental: 50000,
                },
            },
        });

        // Create student
        const studentAuth = await AuthUserModel.create({
            firebaseUid: 'student-uid',
            email: 'student@test.com',
            role: 'student',
            tenantId: tenantId,
        });

        student = await StudentModel.create({
            authUserId: studentAuth._id,
            name: 'Test Student',
            email: 'student@test.com',
            phone: '+57 300 123 4567',
            membershipType: 'basic',
            tenantId: tenantId,
        });

        // Create professor
        const professorAuth = await AuthUserModel.create({
            firebaseUid: 'professor-uid',
            email: 'professor@test.com',
            role: 'professor',
            tenantId: tenantId,
        });

        professor = await ProfessorModel.create({
            authUserId: professorAuth._id,
            name: 'Test Professor',
            email: 'professor@test.com',
            phone: '+57 300 987 6543',
            hourlyRate: 50000,
            tenantId: tenantId,
        });

        // Create court
        court = await CourtModel.create({
            tenantId: tenantId,
            name: 'Cancha 1',
            type: 'tennis',
            price: 50000,
            isActive: true,
        });
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    describe('Scenario 1: Wompi Recharge Flow', () => {
        it('should create Payment without bookingId when student recharges via Wompi', async () => {
            // Simulate Wompi payment (recharge)
            const rechargeAmount = 500000;

            // Create StudentTenant first (simulating what PaymentController does)
            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenant._id },
                { $inc: { balance: rechargeAmount } },
                { upsert: true, new: true }
            );

            const payment = await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                amount: rechargeAmount,
                date: new Date(),
                status: 'paid',
                method: 'transfer',
                description: 'Recarga vía Wompi',
                concept: 'Recarga de saldo',
                isOnline: true,
                // No bookingId - this is a recharge
            });

            expect(payment.bookingId).toBeUndefined();
            expect(payment.status).toBe('paid');
            expect(payment.amount).toBe(rechargeAmount);

            // Verify balance is updated
            const studentTenant = await StudentTenantModel.findOne({
                studentId: student._id,
                tenantId: tenant._id,
            });

            expect(studentTenant).toBeTruthy();
            expect(studentTenant!.balance).toBe(rechargeAmount);

            // Verify balance calculation
            const calculatedBalance = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(calculatedBalance).toBe(rechargeAmount);
        });
    });

    describe('Scenario 2: Booking with Sufficient Balance', () => {
        it('should create Payment with bookingId and method wallet when booking is paid with balance', async () => {
            // 1. First, recharge balance
            const rechargeAmount = 500000;
            await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                amount: rechargeAmount,
                date: new Date(),
                status: 'paid',
                method: 'transfer',
                description: 'Recarga vía Wompi',
                isOnline: true,
            });

            // Update StudentTenant balance manually (simulating what happens in PaymentController)
            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenant._id },
                { $inc: { balance: rechargeAmount } },
                { upsert: true, new: true }
            );

            // 2. Create booking with sufficient balance
            const bookingPrice = 50000;
            const startTime = new Date('2024-02-01T10:00:00Z');
            const endTime = new Date('2024-02-01T11:00:00Z');

            // Ensure tenant exists and is fresh from DB with online payments enabled
            const freshTenant = await TenantModel.findById(tenant._id);
            expect(freshTenant).toBeTruthy();
            expect(freshTenant!.config?.payments?.enableOnlinePayments).toBe(true);

            // Verify StudentTenant has correct balance
            const studentTenantBefore = await StudentTenantModel.findOne({
                studentId: student._id,
                tenantId: tenant._id,
            });
            expect(studentTenantBefore).toBeTruthy();
            expect(studentTenantBefore!.balance).toBeGreaterThanOrEqual(bookingPrice);

            const booking = await bookingService.createBooking({
                studentId: student._id.toString(),
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                startTime,
                endTime,
                serviceType: 'court_rental',
                price: bookingPrice,
            });

            expect(booking).toBeTruthy();
            expect(booking.status).toBe('pending'); // Booking starts as pending
            expect(booking.price).toBe(bookingPrice);

            // 3. Verify Payment was created automatically with method 'wallet'
            const walletPayment = await PaymentModel.findOne({
                bookingId: booking._id,
                method: 'wallet',
                status: 'paid',
            });

            expect(walletPayment).toBeTruthy();
            expect(walletPayment!.amount).toBe(bookingPrice);
            expect(walletPayment!.bookingId?.toString()).toBe(booking._id.toString());

            // 4. Verify balance was deducted in StudentTenant
            const studentTenant = await StudentTenantModel.findOne({
                studentId: student._id,
                tenantId: tenant._id,
            });

            expect(studentTenant!.balance).toBe(rechargeAmount - bookingPrice);

            // 5. Verify balance calculation
            // The BalanceService calculates: Recargas - Deudas - Gastos con wallet + Pagos recibidos
            // - Recharge payment (500k, no bookingId): +500k (recarga)
            // - Wallet payment (50k, with bookingId, method='wallet'): -50k (gasto ya descontado)
            // - Booking (50k, has paid payment): Not counted as debt (has paid payment)
            // Balance = 500k - 0 - 50k + 0 = 450k
            const calculatedBalance = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            
            // The calculated balance should match the actual balance in StudentTenant
            expect(calculatedBalance).toBe(rechargeAmount - bookingPrice); // 450k
            expect(studentTenant!.balance).toBe(rechargeAmount - bookingPrice); // 450k
        });

        it('should NOT create Payment with wallet if online payments are disabled', async () => {
            // Disable online payments
            await TenantModel.findByIdAndUpdate(tenant._id, {
                'config.payments.enableOnlinePayments': false,
            });

            // Recharge balance
            const rechargeAmount = 500000;
            await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                amount: rechargeAmount,
                date: new Date(),
                status: 'paid',
                method: 'transfer',
                description: 'Recarga vía Wompi',
                isOnline: true,
            });

            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenant._id },
                { $inc: { balance: rechargeAmount } },
                { upsert: true, new: true }
            );

            // Create booking
            const bookingPrice = 50000;
            const startTime = new Date('2024-02-01T10:00:00Z');
            const endTime = new Date('2024-02-01T11:00:00Z');

            // Ensure tenant exists and is fresh from DB
            const freshTenant2 = await TenantModel.findById(tenant._id);
            expect(freshTenant2).toBeTruthy();

            const booking = await bookingService.createBooking({
                studentId: student._id.toString(),
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                startTime,
                endTime,
                serviceType: 'court_rental',
                price: bookingPrice,
            });

            // Verify NO Payment was created (payment to professor)
            const walletPayment = await PaymentModel.findOne({
                bookingId: booking._id,
                method: 'wallet',
            });

            expect(walletPayment).toBeNull();
        });
    });

    describe('Scenario 3: Admin Confirming Payment', () => {
        it('should NOT duplicate balance when admin confirms payment for booking already paid with wallet', async () => {
            // 1. Recharge balance
            const rechargeAmount = 500000;
            await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                amount: rechargeAmount,
                date: new Date(),
                status: 'paid',
                method: 'transfer',
                isOnline: true,
            });

            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenant._id },
                { $inc: { balance: rechargeAmount } },
                { upsert: true, new: true }
            );

            // 2. Create booking (creates Payment with wallet)
            const bookingPrice = 50000;
            const startTime = new Date('2024-02-01T10:00:00Z');
            const endTime = new Date('2024-02-01T11:00:00Z');

            // Ensure tenant exists and is fresh from DB
            const freshTenant3 = await TenantModel.findById(tenant._id);
            expect(freshTenant3).toBeTruthy();

            const booking = await bookingService.createBooking({
                studentId: student._id.toString(),
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                startTime,
                endTime,
                serviceType: 'court_rental',
                price: bookingPrice,
            });

            // Verify Payment with wallet was created
            const walletPayment = await PaymentModel.findOne({
                bookingId: booking._id,
                method: 'wallet',
                status: 'paid',
            });
            expect(walletPayment).toBeTruthy();
            expect(walletPayment!.amount).toBe(bookingPrice);

            // Get balance before admin confirmation
            // The BalanceService calculates: Recargas - Deudas - Gastos con wallet + Pagos recibidos
            // - Recarga: 500k
            // - Gasto con wallet: 50k (ya descontado)
            // Balance = 500k - 0 - 50k = 450k
            const balanceBefore = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceBefore).toBe(rechargeAmount - bookingPrice); // 450k

            // 3. Admin tries to confirm payment
            const req = {
                params: { id: booking._id.toString() },
                body: { paymentStatus: 'paid' },
                tenantId: tenant._id.toString(),
            } as any;

            const res = {
                status: jest.fn().mockReturnThis(),
                json: jest.fn(),
            } as any;

            await tenantAdminController.confirmBooking(req, res);

            // 4. Verify no duplicate payment was created
            const payments = await PaymentModel.find({
                bookingId: booking._id,
            });
            expect(payments).toHaveLength(1); // Only the wallet payment

            // 5. Verify balance did NOT increase
            const balanceAfter = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceAfter).toBe(balanceBefore);
        });

        it('should create payment and add balance when admin confirms payment for booking NOT paid with wallet', async () => {
            // Create booking WITHOUT sufficient balance (no wallet payment created)
            // First, disable online payments to simulate payment to professor
            await TenantModel.findByIdAndUpdate(tenant._id, {
                'config.payments.enableOnlinePayments': false,
            });

            const bookingPrice = 50000;
            const startTime = new Date('2024-02-01T10:00:00Z');
            const endTime = new Date('2024-02-01T11:00:00Z');

            const booking = await bookingService.createBooking({
                studentId: student._id.toString(),
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                startTime,
                endTime,
                serviceType: 'court_rental',
                price: bookingPrice,
            });

            // Verify no wallet payment exists
            const walletPayment = await PaymentModel.findOne({
                bookingId: booking._id,
                method: 'wallet',
            });
            expect(walletPayment).toBeNull();

            // Get balance before admin confirmation
            // Balance = 0 (recargas) - 50k (deuda del booking) = -50k
            const balanceBefore = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceBefore).toBe(-bookingPrice); // -50k (deuda)

            // Admin confirms payment
            const req = {
                params: { id: booking._id.toString() },
                body: { paymentStatus: 'paid' },
                tenantId: tenant._id.toString(),
            } as any;

            const res = {
                status: jest.fn().mockReturnThis(),
                json: jest.fn(),
            } as any;

            await tenantAdminController.confirmBooking(req, res);

            // Verify payment was created
            const payments = await PaymentModel.find({
                bookingId: booking._id,
            });
            expect(payments).toHaveLength(1);
            expect(payments[0]!.method).toBe('cash');
            expect(payments[0]!.status).toBe('paid');

            // Verify balance was added (pago recibido del admin/profesor)
            // Balance = 0 (recargas) - 0 (deuda, booking tiene Payment) + 50k (pago recibido) = 50k
            // El balance aumenta porque:
            // 1. El booking deja de contar como deuda (se cancela la deuda de -50k)
            // 2. El Payment con cash suma al balance (pago recibido de +50k)
            // Neto: -50k (deuda cancelada) + 50k (pago recibido) = 0 cambio en deuda, pero +50k en crédito
            // Total: -50k + 50k + 50k = 50k
            const balanceAfter = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceAfter).toBe(bookingPrice); // 50k (pago recibido)
        });
    });

    describe('Scenario 4: Professor Completing Class', () => {
        it('should NOT add balance when professor completes class with wallet payment', async () => {
            // 1. Recharge balance
            const rechargeAmount = 500000;
            await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                amount: rechargeAmount,
                date: new Date(),
                status: 'paid',
                method: 'transfer',
                isOnline: true,
            });

            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenantId },
                { $inc: { balance: rechargeAmount } },
                { upsert: true, new: true }
            );

            // 2. Create schedule and booking for class
            const schedule = await ScheduleModel.create({
                professorId: professor._id,
                studentId: student._id,
                startTime: new Date('2024-02-01T10:00:00Z'),
                endTime: new Date('2024-02-01T11:00:00Z'),
                status: 'confirmed',
                date: new Date('2024-02-01'),
                tenantId: tenant._id,
            });

            const bookingPrice = 50000;
            const booking = await BookingModel.create({
                scheduleId: schedule._id,
                studentId: student._id,
                professorId: professor._id,
                serviceType: 'individual_class',
                status: 'confirmed',
                price: bookingPrice,
                tenantId: tenant._id,
            });

            // 3. Create wallet payment (simulating booking with balance)
            await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                professorId: professor._id,
                bookingId: booking._id,
                amount: bookingPrice,
                date: new Date(),
                status: 'paid',
                method: 'wallet',
                description: 'Pago con saldo: individual_class',
            });

            // Update balance (simulating deduction)
            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenant._id },
                { $inc: { balance: -bookingPrice } },
                { upsert: true, new: true }
            );

            // Get balance before professor completes class
            const balanceBefore = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );

            // 4. Professor completes class
            const req = {
                params: { scheduleId: schedule._id.toString() },
                body: {
                    paymentAmount: bookingPrice,
                    paymentStatus: 'paid',
                },
                tenantId: tenant._id.toString(),
                user: { uid: 'professor-uid', role: 'professor' },
            } as any;

            const res = {
                status: jest.fn().mockReturnThis(),
                json: jest.fn(),
            } as any;

            await professorDashboardController.completeClass(req, res);

            // 5. Verify balance did NOT increase (wallet payment already deducted)
            const balanceAfter = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceAfter).toBe(balanceBefore);

            // Verify no duplicate payment was created
            const payments = await PaymentModel.find({
                bookingId: booking._id,
            });
            expect(payments).toHaveLength(1);
            expect(payments[0]!.method).toBe('wallet');
        });

        it('should add balance when professor completes class with cash payment (no wallet payment)', async () => {
            // Create schedule and booking for class (no wallet payment)
            const schedule = await ScheduleModel.create({
                professorId: professor._id,
                studentId: student._id,
                startTime: new Date('2024-02-01T10:00:00Z'),
                endTime: new Date('2024-02-01T11:00:00Z'),
                status: 'confirmed',
                date: new Date('2024-02-01'),
                tenantId: tenant._id,
            });

            const bookingPrice = 50000;
            const booking = await BookingModel.create({
                scheduleId: schedule._id,
                studentId: student._id,
                professorId: professor._id,
                serviceType: 'individual_class',
                status: 'confirmed',
                price: bookingPrice,
                tenantId: tenant._id,
            });

            // Get balance before professor completes class
            // Balance = 0 (recargas) - 50k (deuda del booking) = -50k
            const balanceBefore = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceBefore).toBe(-bookingPrice); // -50k (deuda)

            // Professor completes class with cash payment
            const req = {
                params: { scheduleId: schedule._id.toString() },
                body: {
                    paymentAmount: bookingPrice,
                    paymentStatus: 'paid',
                },
                tenantId: tenant._id.toString(),
                user: { uid: 'professor-uid', role: 'professor' },
            } as any;

            const res = {
                status: jest.fn().mockReturnThis(),
                json: jest.fn(),
            } as any;

            await professorDashboardController.completeClass(req, res);

            // Verify balance was added (pago recibido del profesor)
            // Balance = 0 (recargas) - 0 (deuda, booking tiene Payment) + 50k (pago recibido) = 50k
            const balanceAfter = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balanceAfter).toBe(bookingPrice); // 50k (pago recibido)

            // Verify payment was created
            const payments = await PaymentModel.find({
                bookingId: booking._id,
            });
            expect(payments).toHaveLength(1);
            expect(payments[0]!.method).toBe('cash');
            expect(payments[0]!.status).toBe('paid');
        });
    });

    describe('Scenario 5: Complete Flow - Recharge, Bookings, and Balance Calculation', () => {
        it('should correctly calculate balance through complete flow', async () => {
            // 1. Recharge 500k
            const rechargeAmount = 500000;
            await PaymentModel.create({
                studentId: student._id,
                tenantId: tenant._id,
                amount: rechargeAmount,
                date: new Date(),
                status: 'paid',
                method: 'transfer',
                description: 'Recarga vía Wompi',
                isOnline: true,
            });

            await StudentTenantModel.findOneAndUpdate(
                { studentId: student._id, tenantId: tenant._id },
                { $inc: { balance: rechargeAmount } },
                { upsert: true, new: true }
            );

            let balance = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(balance).toBe(rechargeAmount);

            // 2. Create booking 1 (50k) - paid with balance
            // Ensure tenant exists and is fresh from DB
            const freshTenant5 = await TenantModel.findById(tenant._id);
            expect(freshTenant5).toBeTruthy();

            const booking1Price = 50000;
            const booking1 = await bookingService.createBooking({
                studentId: student._id.toString(),
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                startTime: new Date('2024-02-01T10:00:00Z'),
                endTime: new Date('2024-02-01T11:00:00Z'),
                serviceType: 'court_rental',
                price: booking1Price,
            });

            // Verify Payment with wallet was created for booking1
            const walletPayment1 = await PaymentModel.findOne({
                bookingId: booking1._id,
                method: 'wallet',
                status: 'paid',
            });
            expect(walletPayment1).toBeTruthy();
            expect(walletPayment1!.amount).toBe(booking1Price);

            balance = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            // Balance = 500k (recarga) - 0 (deudas) - 50k (gasto con wallet) = 450k
            expect(balance).toBe(rechargeAmount - booking1Price);
            
            // Verify actual balance in StudentTenant matches calculated balance
            const studentTenant1 = await StudentTenantModel.findOne({
                studentId: student._id,
                tenantId: tenant._id,
            });
            expect(studentTenant1!.balance).toBe(rechargeAmount - booking1Price);

            // 3. Create booking 2 (50k) - paid with balance
            const booking2 = await bookingService.createBooking({
                studentId: student._id.toString(),
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                startTime: new Date('2024-02-01T12:00:00Z'),
                endTime: new Date('2024-02-01T13:00:00Z'),
                serviceType: 'court_rental',
                price: booking1Price,
            });

            // Verify Payment with wallet was created for booking2
            const walletPayment2 = await PaymentModel.findOne({
                bookingId: booking2._id,
                method: 'wallet',
                status: 'paid',
            });
            expect(walletPayment2).toBeTruthy();
            expect(walletPayment2!.amount).toBe(booking1Price);

            balance = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            // Balance = 500k (recarga) - 0 (deudas) - 50k (gasto wallet 1) - 50k (gasto wallet 2) = 400k
            expect(balance).toBe(rechargeAmount - booking1Price - booking1Price);
            
            // Verify actual balance in StudentTenant matches calculated balance
            const studentTenant2 = await StudentTenantModel.findOne({
                studentId: student._id,
                tenantId: tenant._id,
            });
            expect(studentTenant2!.balance).toBe(rechargeAmount - booking1Price - booking1Price);

            // 4. Verify all payments
            const rechargePayments = await PaymentModel.find({
                studentId: student._id,
                tenantId: tenant._id,
                bookingId: { $exists: false },
            });
            expect(rechargePayments).toHaveLength(1);
            expect(rechargePayments[0]!.amount).toBe(rechargeAmount);

            const walletPayments = await PaymentModel.find({
                studentId: student._id,
                tenantId: tenant._id,
                method: 'wallet',
            });
            expect(walletPayments).toHaveLength(2);

            // 5. Verify final balance
            // The BalanceService calculates: Recargas - Deudas - Gastos con wallet + Pagos recibidos
            // - Recarga: 500k
            // - Gastos con wallet: 50k + 50k = 100k
            // Balance = 500k - 0 - 100k = 400k
            const finalBalance = await balanceService.calculateBalance(
                student._id,
                tenant._id
            );
            expect(finalBalance).toBe(400000); // 500k - 50k - 50k
            
            // Verify actual balance in StudentTenant matches calculated balance
            const studentTenantFinal = await StudentTenantModel.findOne({
                studentId: student._id,
                tenantId: tenant._id,
            });
            expect(studentTenantFinal!.balance).toBe(400000); // 500k - 50k - 50k
        });
    });
});


import { describe, it, beforeEach, expect, jest, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Types } from 'mongoose';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { Request, Response } from 'express';

describe('Integration Test: Court Conflict Validation in Professor Schedule', () => {
    let mongo: MongoMemoryServer;
    let controller: ProfessorDashboardController;

    beforeAll(async () => {
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        await mongoose.connect(mongoUri);
        controller = new ProfessorDashboardController();
    });

    beforeEach(async () => {
        await AuthUserModel.deleteMany({});
        await ProfessorModel.deleteMany({});
        await ScheduleModel.deleteMany({});
        await BookingModel.deleteMany({});
        await CourtModel.deleteMany({});
        await TenantModel.deleteMany({});
        await ProfessorTenantModel.deleteMany({});
        await StudentModel.deleteMany({});
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    it('should deny creating a schedule if the court is already occupied by a booking (court_rental)', async () => {
        // 1. Setup Data
        const adminUser = await AuthUserModel.create({ email: 'admin@test.com', name: 'Admin', role: 'tenant_admin', firebaseUid: 'admin-uid' });
        const tenant = await TenantModel.create({ name: 'Tennis Club', domain: 'club', isActive: true, adminUserId: adminUser._id });
        const court = await CourtModel.create({ name: 'Court 1', tenantId: tenant._id, type: 'tennis', surface: 'clay', isActive: true, price: 50 });

        const profAuth = await AuthUserModel.create({ email: 'prof@test.com', name: 'Prof', role: 'professor', firebaseUid: 'prof-uid' });
        const professor = await ProfessorModel.create({ authUserId: profAuth._id, name: 'Prof', email: 'prof@test.com', phone: '123456', hourlyRate: 50, experienceYears: 5 });
        await ProfessorTenantModel.create({ professorId: professor._id, tenantId: tenant._id, isActive: true });

        const studentAuth = await AuthUserModel.create({ email: 'student@test.com', name: 'Student', role: 'student', firebaseUid: 'student-uid' });
        const student = await StudentModel.create({ authUserId: studentAuth._id, name: 'Student', email: 'student@test.com', balance: 1000, membershipType: 'basic' });

        // 2. Create an existing booking (court rental)
        const startTime = new Date();
        startTime.setUTCHours(10, 0, 0, 0);
        const endTime = new Date(startTime);
        endTime.setUTCHours(11, 0, 0, 0);

        await BookingModel.create({
            tenantId: tenant._id,
            studentId: student._id,
            courtId: court._id,
            serviceType: 'court_rental',
            price: 100,
            status: 'confirmed',
            bookingDate: startTime,
            endTime: endTime
        });

        // 3. Try to create a conflicting schedule as professor
        const req = {
            user: { id: profAuth._id.toString(), uid: 'prof-uid' },
            body: {
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                date: startTime.toISOString(),
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString()
            }
        } as unknown as Request;

        const mockJson = jest.fn();
        const mockStatus = jest.fn().mockReturnValue({ json: mockJson });
        const res = { status: mockStatus, json: mockJson } as unknown as Response;

        await controller.createSchedule(req, res);

        // 4. Verify conflict response
        expect(mockStatus).toHaveBeenCalledWith(409);
        expect(mockJson).toHaveBeenCalledWith(expect.objectContaining({
            error: 'COURT_OCCUPIED'
        }));
    });

    it('should deny creating a schedule if the court is already occupied by another professor schedule', async () => {
        // 1. Setup Data
        const adminUser = await AuthUserModel.create({ email: 'admin@test.com', name: 'Admin', role: 'tenant_admin', firebaseUid: 'admin-uid' });
        const tenant = await TenantModel.create({ name: 'Tennis Club', domain: 'club', isActive: true, adminUserId: adminUser._id });
        const court = await CourtModel.create({ name: 'Court 1', tenantId: tenant._id, type: 'tennis', surface: 'clay', isActive: true, price: 50 });

        const prof1Auth = await AuthUserModel.create({ email: 'prof1@test.com', name: 'Prof 1', role: 'professor', firebaseUid: 'prof1-uid' });
        const professor1 = await ProfessorModel.create({ authUserId: prof1Auth._id, name: 'Prof 1', email: 'prof1@test.com', phone: '123456', hourlyRate: 50, experienceYears: 5 });
        await ProfessorTenantModel.create({ professorId: professor1._id, tenantId: tenant._id, isActive: true });

        const prof2Auth = await AuthUserModel.create({ email: 'prof2@test.com', name: 'Prof 2', role: 'professor', firebaseUid: 'prof2-uid' });
        const professor2 = await ProfessorModel.create({ authUserId: prof2Auth._id, name: 'Prof 2', email: 'prof2@test.com', phone: '654321', hourlyRate: 50, experienceYears: 5 });
        await ProfessorTenantModel.create({ professorId: professor2._id, tenantId: tenant._id, isActive: true });

        const startTime = new Date();
        startTime.setUTCHours(14, 0, 0, 0);
        const endTime = new Date(startTime);
        endTime.setUTCHours(15, 0, 0, 0);

        // 2. Create existing schedule for Professor 1
        await ScheduleModel.create({
            tenantId: tenant._id,
            professorId: professor1._id,
            courtId: court._id,
            date: startTime,
            startTime: startTime,
            endTime: endTime,
            isAvailable: true,
            status: 'pending'
        });

        // 3. Try to create a conflicting schedule for Professor 2
        const req = {
            user: { id: prof2Auth._id.toString(), uid: 'prof2-uid' },
            body: {
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                date: startTime.toISOString(),
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString()
            }
        } as unknown as Request;

        const mockJson = jest.fn();
        const mockStatus = jest.fn().mockReturnValue({ json: mockJson });
        const res = { status: mockStatus, json: mockJson } as unknown as Response;

        await controller.createSchedule(req, res);

        // 4. Verify conflict response
        expect(mockStatus).toHaveBeenCalledWith(409);
        expect(mockJson).toHaveBeenCalledWith(expect.objectContaining({
            error: 'COURT_OCCUPIED'
        }));
    });

    it('should create a schedule successfully if there are no conflicts', async () => {
        // 1. Setup Data
        const adminUser = await AuthUserModel.create({ email: 'admin@test.com', name: 'Admin', role: 'tenant_admin', firebaseUid: 'admin-uid' });
        const tenant = await TenantModel.create({ name: 'Tennis Club', domain: 'club', isActive: true, adminUserId: adminUser._id });
        const court = await CourtModel.create({ name: 'Court 1', tenantId: tenant._id, type: 'tennis', surface: 'clay', isActive: true, price: 50 });

        const profAuth = await AuthUserModel.create({ email: 'prof@test.com', name: 'Prof', role: 'professor', firebaseUid: 'prof-uid' });
        const professor = await ProfessorModel.create({ authUserId: profAuth._id, name: 'Prof', email: 'prof@test.com', phone: '123456', hourlyRate: 50, experienceYears: 5 });
        await ProfessorTenantModel.create({ professorId: professor._id, tenantId: tenant._id, isActive: true });

        const startTime = new Date();
        startTime.setUTCHours(16, 0, 0, 0);
        const endTime = new Date(startTime);
        endTime.setUTCHours(17, 0, 0, 0);

        // 2. Call createSchedule
        const req = {
            user: { id: profAuth._id.toString(), uid: 'prof-uid' },
            body: {
                tenantId: tenant._id.toString(),
                courtId: court._id.toString(),
                date: startTime.toISOString(),
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString()
            }
        } as unknown as Request;

        const mockJson = jest.fn();
        const mockStatus = jest.fn().mockReturnValue({ json: mockJson });
        const res = { status: mockStatus, json: mockJson } as unknown as Response;

        await controller.createSchedule(req, res);

        // 3. Verify success response
        expect(mockStatus).not.toHaveBeenCalledWith(400);
        expect(mockStatus).not.toHaveBeenCalledWith(409);
        expect(mockStatus).not.toHaveBeenCalledWith(500);

        const created = await ScheduleModel.findOne({ professorId: professor._id });
        expect(created).toBeDefined();
        expect(created?.courtId?.toString()).toBe(court._id.toString());
    });
});

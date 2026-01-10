
import { describe, it, beforeEach, expect, jest, beforeAll, afterAll } from '@jest/globals';
import { MongoMemoryServer } from 'mongodb-memory-server';
import mongoose, { Types } from 'mongoose';
import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { Request, Response } from 'express';

describe('Bug Reproduction: Student Booking Blocked slots', () => {
    let mongo: MongoMemoryServer;
    let controller: StudentDashboardController;

    beforeAll(async () => {
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        await mongoose.connect(mongoUri);
        controller = new StudentDashboardController();
    });

    beforeEach(async () => {
        await AuthUserModel.deleteMany({});
        await StudentModel.deleteMany({});
        await ProfessorModel.deleteMany({});
        await ScheduleModel.deleteMany({});
        await CourtModel.deleteMany({});
        await TenantModel.deleteMany({});
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    it('should reproduce bug: blocked professor schedule shows as available court slot', async () => {
        // 1. Setup Admin User for Tenant
        const adminUser = await AuthUserModel.create({
            email: 'admin@test.com',
            name: 'Admin Test',
            role: 'tenant_admin',
            firebaseUid: 'admin-uid'
        });

        // 2. Setup Tenant
        const tenant = await TenantModel.create({
            name: 'Test Tennis Club',
            domain: 'test-club',
            isActive: true,
            adminUserId: adminUser._id
        });

        // 3. Setup Court
        const court = await CourtModel.create({
            name: 'Court 1',
            tenantId: tenant._id,
            type: 'tennis',
            surface: 'clay',
            isActive: true,
            price: 100 // Price per hour
        });

        // 3. Setup Professor linked to Tenant
        const profAuth = await AuthUserModel.create({
            email: 'prof@test.com',
            name: 'Professor Test',
            role: 'professor',
            firebaseUid: 'prof-uid'
        });

        const professor = await ProfessorModel.create({
            authUserId: profAuth._id,
            name: 'Professor Test',
            email: 'prof@test.com',
            phone: '+1234567890',
            tenantId: tenant._id, // Important: associated with tenant
            hourlyRate: 50
        });

        // 4. Professor BLOCKS a schedule
        // Let's pick a specific date/time: Tomorrow 10:00 AM - 11:00 AM
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setUTCHours(10, 0, 0, 0);
        const endTime = new Date(tomorrow);
        endTime.setUTCHours(11, 0, 0, 0);

        await ScheduleModel.create({
            tenantId: tenant._id,
            professorId: professor._id,
            date: tomorrow,
            startTime: tomorrow,
            endTime: endTime,
            isAvailable: false, // Not available for lessons
            isBlocked: true, // EXPLICITLY BLOCKED
            blockReason: 'Personal time',
            courtId: court._id, // NEW: Block specifically for this court
            status: 'confirmed'
        });

        // 5. Setup Student (not strictly needed for availability check but good practice)
        const studentAuth = await AuthUserModel.create({
            email: 'student@test.com',
            name: 'Student Test',
            role: 'student',
            firebaseUid: 'student-uid'
        });

        // 6. Call getCourtAvailableSlots
        // Mock Request and Response
        const req = {
            tenantId: tenant._id.toString(),
            params: {
                courtId: court._id.toString()
            },
            query: {
                date: tomorrow.toISOString().split('T')[0] // YYYY-MM-DD
            }
        } as unknown as Request;

        const mockJson = jest.fn();
        const mockStatus = jest.fn().mockReturnValue({ json: mockJson });
        const res = {
            status: mockStatus,
            json: mockJson
        } as unknown as Response;

        await controller.getCourtAvailableSlots(req, res);

        // Verify response
        expect(mockJson).toHaveBeenCalled();
        const responseData = mockJson.mock.calls[0][0];

        // console.log('Response Data:', JSON.stringify(responseData, null, 2));

        expect(responseData).toHaveProperty('availableSlots');
        const availableSlots = (responseData as any).availableSlots as string[];

        // THE FIX: The slot '10:00' should NOT be in the available list because
        // we now check blocked schedules with matching courtId.
        expect(availableSlots).not.toContain('10:00');
    });
});

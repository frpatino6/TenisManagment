import request from 'supertest';
import mongoose from 'mongoose';
import express, { Application } from 'express';
import { MongoMemoryServer } from 'mongodb-memory-server';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { StudentDashboardController } from '../../application/controllers/StudentDashboardController';
import { ProfessorDashboardController } from '../../application/controllers/ProfessorDashboardController';

describe('Bug Repro: Blocked Schedule Visibility', () => {
    let mongo: MongoMemoryServer;
    let app: Application;
    let tenantId: string;
    let courtId: string;
    let professorId: string;
    let studentId: string;
    let studentDashboardController: StudentDashboardController;
    let professorDashboardController: ProfessorDashboardController;

    beforeAll(async () => {
        mongo = await MongoMemoryServer.create();
        const mongoUri = mongo.getUri();
        await mongoose.connect(mongoUri);

        studentDashboardController = new StudentDashboardController();
        professorDashboardController = new ProfessorDashboardController();

        app = express();
        app.use(express.json());

        // Mock middleware to inject tenantId and user
        const mockAuth = (req: any, res: any, next: any) => {
            req.tenantId = tenantId;
            req.user = { uid: 'prof_firebase_uid', role: 'professor' };
            next();
        };

        const mockStudentAuth = (req: any, res: any, next: any) => {
            req.tenantId = tenantId;
            req.user = { uid: 'student_firebase_uid', role: 'student' };
            next();
        };

        // Routes
        app.post('/api/professor-dashboard/schedules', mockAuth, professorDashboardController.createSchedule);
        app.put('/api/professor-dashboard/schedules/:scheduleId/block', mockAuth, professorDashboardController.blockSchedule);
        app.get('/api/student-dashboard/courts/:courtId/available-slots', mockStudentAuth, studentDashboardController.getCourtAvailableSlots);

        // 1. Create Tenant
        const tenant = await TenantModel.create({
            name: 'Test Tennis Club',
            slug: 'test-tennis-club',
            isActive: true,
            adminUserId: new mongoose.Types.ObjectId(),
            domain: 'test.com',
            config: {
                operatingHours: {
                    schedule: [
                        { dayOfWeek: 0, open: '06:00', close: '22:00' },
                        { dayOfWeek: 1, open: '06:00', close: '22:00' },
                        { dayOfWeek: 2, open: '06:00', close: '22:00' },
                        { dayOfWeek: 3, open: '06:00', close: '22:00' },
                        { dayOfWeek: 4, open: '06:00', close: '22:00' },
                        { dayOfWeek: 5, open: '06:00', close: '22:00' },
                        { dayOfWeek: 6, open: '06:00', close: '22:00' }
                    ]
                }
            }
        });
        tenantId = tenant._id.toString();

        // 2. Create Court
        const court = await CourtModel.create({
            name: 'Court 1',
            tenantId: tenant._id,
            type: 'tennis',
            surface: 'clay',
            isActive: true,
            price: 100
        });
        courtId = court._id.toString();

        // 3. Create Professor
        const profAuth = await AuthUserModel.create({
            email: 'prof@test.com',
            role: 'professor',
            firebaseUid: 'prof_firebase_uid'
        });

        const professor = await ProfessorModel.create({
            authUserId: profAuth._id,
            name: 'Roger Federer',
            email: 'prof@test.com',
            phone: '+1234567890',
            hourlyRate: 100,
            experienceYears: 10
        });
        professorId = professor._id.toString();

        await ProfessorTenantModel.create({
            professorId: professor._id,
            tenantId: tenant._id,
            isActive: true,
            role: 'professor'
        });
    });

    afterAll(async () => {
        await mongoose.disconnect();
        await mongo.stop();
    });

    it('should block a schedule with courtId and ensure it is REMOVED from available slots', async () => {
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setUTCHours(15, 0, 0, 0); // 10:00 Local

        const startTime = new Date(tomorrow);
        const endTime = new Date(tomorrow);
        endTime.setUTCHours(16, 0, 0, 0);

        // 1. Create schedule
        const createRes = await request(app)
            .post('/api/professor-dashboard/schedules')
            .send({
                date: startTime.toISOString(),
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString(),
                tenantId
            });

        expect(createRes.status).toBe(201);
        const scheduleId = createRes.body.id;

        // 2. Block schedule
        const blockRes = await request(app)
            .put(`/api/professor-dashboard/schedules/${scheduleId}/block`)
            .send({
                reason: 'Private Lesson',
                courtId: courtId
            });

        expect(blockRes.status).toBe(200);

        // 3. Check availability
        const dateStr = tomorrow.toISOString().split('T')[0];
        const availRes = await request(app)
            .get(`/api/student-dashboard/courts/${courtId}/available-slots?date=${dateStr}`);

        expect(availRes.status).toBe(200);
        const { availableSlots, bookedSlots } = availRes.body;

        expect(bookedSlots).toContain('15:00');
        expect(availableSlots).not.toContain('15:00');
    });
});
// Close describe block

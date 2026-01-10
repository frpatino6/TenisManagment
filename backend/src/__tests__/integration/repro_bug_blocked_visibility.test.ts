import request from 'supertest';
import mongoose from 'mongoose';
import { app } from '../../presentation/server';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';
import { ProfessorModel } from '../../infrastructure/database/models/ProfessorModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { config } from '../../infrastructure/config';
import jwt from 'jsonwebtoken';

describe('Bug Repro: Blocked Schedule Visibility', () => {
    let tenantId: string;
    let professorToken: string;
    let studentToken: string; // We'll mock a student token for checking availability
    let courtId: string;
    let professorId: string;
    let scheduleId: string;

    beforeAll(async () => {

        // Connect to test DB
        // Connect to test DB
        await mongoose.connect(config.mongoUri, { dbName: 'test_blocked_visibility', connectTimeoutMS: 60000 });

        // Clear DB
        await mongoose.connection.db.dropDatabase();

        // 1. Create Tenant
        const tenant = await TenantModel.create({
            name: 'Test Tennis Club',
            slug: 'test-tennis-club',
            isActive: true,
            ownerId: new mongoose.Types.ObjectId(),
            domain: 'test.com',
            config: {
                operatingHours: {
                    open: '06:00',
                    close: '22:00',
                    daysOfWeek: [0, 1, 2, 3, 4, 5, 6]
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

        // 3. Create Professor User & Model
        const profAuth = await AuthUserModel.create({
            email: 'prof@test.com',
            password: 'hashed_password',
            role: 'professor',
            firebaseUid: 'prof_firebase_uid'
        });

        const professor = await ProfessorModel.create({
            authUserId: profAuth._id,
            name: 'Roger Federer',
            email: 'prof@test.com',
            tenantId: tenant._id
        });
        professorId = professor._id.toString();

        await ProfessorTenantModel.create({
            professorId: professor._id,
            tenantId: tenant._id,
            isActive: true,
            role: 'professor'
        });

        // Generate Token
        professorToken = jwt.sign({ uid: 'prof_firebase_uid', role: 'professor' }, config.jwtSecret);
        studentToken = jwt.sign({ uid: 'student_firebase_uid', role: 'student' }, config.jwtSecret); // Just need a valid token format usually
    }, 60000); // 60s timeout for setup

    afterAll(async () => {
        await mongoose.connection.db.dropDatabase();
        await mongoose.connection.close();
    });

    it('should block a schedule with courtId and ensure it is REMOVED from available slots', async () => {
        // 1. Professor creates a schedule
        // Create for tomorrow at 10:00 AM UTC
        const tomorrow = new Date();
        tomorrow.setDate(tomorrow.getDate() + 1);
        tomorrow.setUTCHours(15, 0, 0, 0); // 15:00 UTC = 10:00 Local (UTC-5)

        const startTime = new Date(tomorrow);
        const endTime = new Date(tomorrow);
        endTime.setUTCHours(16, 0, 0, 0); // 16:00 UTC

        const createRes = await request(app)
            .post('/api/professor-dashboard/schedules')
            .set('Authorization', `Bearer ${professorToken}`)
            .send({
                date: startTime.toISOString(),
                startTime: startTime.toISOString(),
                endTime: endTime.toISOString(),
                tenantId,
                courtId // Assign court immediately or later? UI does "create" then "block" or just "create"? UI creates available then blocks.
            });

        // The UI flow: Create Schedule -> Show in List -> Click Block -> Select Court -> Send Block Request
        // So let's create normally first (without courtId, as regular schedule is just "available")
        // Wait, createSchedule endpoint accepts courtId now? Yes, I added it. But let's follow the standard flow where it might be added during block.
        // Actually, createSchedule creates an AVAILABLE slot.
        // Let's assume we created it available first.

        expect(createRes.status).toBe(201);
        scheduleId = createRes.body.id;

        // 2. Professor BLOCKS the schedule with courtId
        const blockRes = await request(app)
            .put(`/api/professor-dashboard/schedules/${scheduleId}/block`)
            .set('Authorization', `Bearer ${professorToken}`)
            .send({
                reason: 'Private Lesson',
                courtId: courtId
            });

        expect(blockRes.status).toBe(200);

        // Verify in DB that courtId is set
        const schedule = await ScheduleModel.findById(scheduleId);
        expect(schedule).toBeDefined();
        expect(schedule?.isBlocked).toBe(true);
        expect(schedule?.courtId?.toString()).toBe(courtId);

        // 3. Check Court Availability as Student
        // We expect the slot at 10:00 to be MISSING from availableSlots OR present in bookedSlots

        // We check availability for "tomorrow"
        const dateStr = tomorrow.toISOString().split('T')[0];

        // Need to mock tenantId middleware or pass header if required
        // The student dashboard usually infers tenant from context or sends it?
        // getCourtAvailableSlots requires courtId in path. 
        // It gets tenantId from req.tenantId which comes from... where?
        // 'tenant' middleware usually extracts x-tenant-id header.

        const availRes = await request(app)
            .get(`/api/student-dashboard/courts/${courtId}/available-slots?date=${dateStr}`)
            .set('Authorization', `Bearer ${studentToken}`)
            .set('x-tenant-id', tenantId);

        expect(availRes.status).toBe(200);

        const { availableSlots, bookedSlots } = availRes.body;

        // Debug output
        console.log('Detected Available Slots:', availableSlots);
        console.log('Detected Booked Slots:', bookedSlots);

        // 10:00 UTC. 
        // The previous logic issue I suspected: 
        // If operatingHours are 06:00-22:00.
        // getCourtAvailableSlots logic:
        //   bookedSlots.add(scheduleStart.getUTCHours() + ':00') -> "10:00"
        //   loop hour 6 to 22.
        //   "10:00" matches "10:00".
        //   So it SHOULD be marked booked.

        // So if the hour is strictly 10, it should be booked.

        expect(bookedSlots).toContain('10:00');
        expect(availableSlots).not.toContain('10:00');
    });
}); // Close describe block


import mongoose, { Types } from 'mongoose';
import { ScheduleModel } from '../infrastructure/database/models/ScheduleModel';
import { BookingModel } from '../infrastructure/database/models/BookingModel';

const MONGO_URI = 'mongodb+srv://frpatino6Coffe:s4ntiago@mycoffecluster.yerjpro.mongodb.net/tennis_mgmt';

async function run() {
    await mongoose.connect(MONGO_URI);
    console.log('Connected to DB');

    // 1. Dump LATEST Blocked Schedules (Sort by _id desc to see newest)
    const allBlocked = await ScheduleModel.find({ isBlocked: true })
        .sort({ _id: -1 })
        .limit(10);

    console.log('--- LATEST 10 BLOCKED SCHEDULES ---');
    allBlocked.forEach(s => {
        console.log({
            id: s._id,
            courtId: s.courtId,
            date: s.date,
            startTime: s.startTime,
            // Check what exact time is stored
            iso: s.startTime.toISOString()
        });
    });

    // 2. Check if ANY block has courtId
    const blocksWithCourt = await ScheduleModel.find({
        isBlocked: true,
        courtId: { $ne: null }
    }).limit(5);

    console.log('\n--- BLOCKS WITH COURT ID (Found: ' + blocksWithCourt.length + ') ---');
    blocksWithCourt.forEach(s => {
        console.log({
            id: s._id,
            courtId: s.courtId,
            startTime: s.startTime
        });
    });

    if (blocksWithCourt.length === 0) {
        if (allBlocked.length > 0) {
            console.log('CRITICAL: Latest blocks exist but NONE have courtId set.');
        } else {
            console.log('No blocked schedules found at all.');
        }
        await mongoose.disconnect();
        return;
    }

    // Pick one VALID block to test
    const sample = blocksWithCourt[0];
    const courtId = sample.courtId;
    const tenantId = sample.tenantId;

    if (!courtId) {
        console.log('Sample has no courtId, cannot test court logic.');
        await mongoose.disconnect();
        return;
    }

    console.log('\n--- TESTING CONTROLLER LOGIC FOR SAMPLE ---');
    console.log(`Tenant: ${tenantId}, Court: ${courtId}`);

    // Test Date: The date of the blocked schedule
    // We want to see if querying this date finds this block
    const targetDateInput = new Date(sample.date); // This might be time-stripped
    // Fix target date to 00:00 UTC of that day
    const targetDate = new Date(Date.UTC(targetDateInput.getUTCFullYear(), targetDateInput.getUTCMonth(), targetDateInput.getUTCDate()));
    const nextDay = new Date(targetDate);
    nextDay.setDate(nextDay.getDate() + 1);

    console.log(`Target Date (UTC): ${targetDate.toISOString()}`);
    console.log(`Next Day (UTC): ${nextDay.toISOString()}`);

    // REPLICATE CONTROLLER LOGIC
    const queryStart = new Date(targetDate);
    queryStart.setDate(queryStart.getDate() - 1);
    const queryEnd = new Date(nextDay);
    queryEnd.setDate(queryEnd.getDate() + 1);

    console.log(`Query Range: ${queryStart.toISOString()} to ${queryEnd.toISOString()}`);

    const blockedSchedules = await ScheduleModel.find({
        tenantId: tenantId,
        courtId: courtId,
        isBlocked: true,
        startTime: {
            $gte: queryStart,
            $lt: queryEnd,
        }
    }).lean();

    console.log(`Found ${blockedSchedules.length} blocks in range.`);

    const bookedSlots = new Set<string>();

    blockedSchedules.forEach((schedule) => {
        const scheduleStart = new Date(schedule.startTime);
        console.log(`\nProcessing Block: ${scheduleStart.toISOString()}`);

        // Logic from Controller
        const localTime = new Date(scheduleStart.getTime() - (5 * 60 * 60 * 1000));
        console.log(`Local Time (UTC-5): ${localTime.toISOString()}`);

        const isSameDay =
            localTime.getUTCFullYear() === targetDate.getUTCFullYear() &&
            localTime.getUTCMonth() === targetDate.getUTCMonth() &&
            localTime.getUTCDate() === targetDate.getUTCDate();

        console.log(`Is Same Day as ${targetDate.toISOString()}? ${isSameDay}`);

        if (isSameDay) {
            const hour = localTime.getUTCHours();
            const slot = `${hour.toString().padStart(2, '0')}:00`;
            console.log(`>> BLOCKED SLOT: ${slot}`);
            bookedSlots.add(slot);
        } else {
            console.log('>> SKIPPED (Different Day)');
        }
    });

    console.log('\nFinal Booked Slots:', Array.from(bookedSlots));

    await mongoose.disconnect();
}

run().catch(console.error);

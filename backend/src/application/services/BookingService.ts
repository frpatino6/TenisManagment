import { Types } from 'mongoose';
import { BookingModel, BookingDocument } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { TenantService } from './TenantService';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'BookingService' });

export interface CreateBookingData {
    tenantId: string | Types.ObjectId;
    scheduleId: string | Types.ObjectId;
    studentId: string | Types.ObjectId;
    serviceType: 'individual_class' | 'group_class' | 'court_rental';
    price: number;
}

export class BookingService {
    private tenantService = new TenantService();

    /**
     * Creates a booking and updates the schedule.
     * Centralized logic to be used by controllers and webhooks.
     */
    async createBooking(data: CreateBookingData): Promise<BookingDocument> {
        const { tenantId, scheduleId, studentId, serviceType, price } = data;

        try {
            // 1. Get schedule and validate
            const schedule = await ScheduleModel.findById(scheduleId);
            if (!schedule) {
                throw new Error('Horario no encontrado');
            }

            if (!schedule.isAvailable) {
                throw new Error('Este horario ya no está disponible');
            }

            // 2. Validate professor is active in tenant
            const professorTenant = await ProfessorTenantModel.findOne({
                professorId: schedule.professorId,
                tenantId: tenantId,
                isActive: true
            });

            if (!professorTenant) {
                throw new Error('El profesor ya no está asociado activamente a este centro');
            }

            // 3. Ensure StudentTenant relationship exists
            await this.tenantService.addStudentToTenant(studentId.toString(), tenantId.toString());

            // 4. Find an available court
            const availableCourt = await this.findAvailableCourt(
                new Types.ObjectId(tenantId.toString()),
                schedule.startTime,
                schedule.endTime
            );

            if (!availableCourt) {
                throw new Error('No hay canchas disponibles para este horario');
            }

            // 5. Create the booking
            const booking = await BookingModel.create({
                tenantId: new Types.ObjectId(tenantId.toString()),
                scheduleId: schedule._id,
                studentId: new Types.ObjectId(studentId.toString()),
                professorId: schedule.professorId,
                courtId: availableCourt._id,
                serviceType: serviceType,
                price: price,
                status: 'confirmed',
                notes: `Reserva de ${serviceType} - Cancha: ${availableCourt.name}`
            });

            // 6. Update schedule
            schedule.isAvailable = false;
            schedule.studentId = new Types.ObjectId(studentId.toString());
            schedule.status = 'confirmed';
            await schedule.save();

            logger.info('Booking created successfully', {
                bookingId: booking._id.toString(),
                scheduleId: scheduleId.toString(),
                studentId: studentId.toString()
            });

            return booking;
        } catch (error) {
            logger.error('Error creating booking in service', { error: (error as Error).message, data });
            throw error;
        }
    }

    /**
     * Find an available court for a given time range
     * Returns the first available court, or null if none available
     */
    async findAvailableCourt(
        tenantId: Types.ObjectId,
        startTime: Date,
        endTime: Date,
    ): Promise<{ _id: Types.ObjectId; name: string } | null> {
        // Get all active courts for this tenant
        const courts = await CourtModel.find({
            tenantId: tenantId,
            isActive: true,
        }).lean();

        if (courts.length === 0) {
            return null;
        }

        // Find all bookings that have a courtId assigned and might overlap with the requested time
        const bookingsWithCourt = await BookingModel.find({
            tenantId: tenantId,
            courtId: { $exists: true, $ne: null },
            status: { $in: ['confirmed', 'pending'] },
        })
            .populate('scheduleId')
            .lean();

        // Create a set of occupied court IDs during this time
        const occupiedCourtIds = new Set<string>();

        bookingsWithCourt.forEach((booking: any) => {
            if (!booking.courtId) return;

            let bookingStart: Date;
            let bookingEnd: Date;

            if (booking.serviceType === 'court_rental' && booking.bookingDate) {
                // Court rental: use bookingDate as start, assume 1 hour duration
                bookingStart = new Date(booking.bookingDate);
                bookingEnd = new Date(bookingStart);
                bookingEnd.setUTCHours(bookingEnd.getUTCHours() + 1);
            } else if (booking.scheduleId && (booking.scheduleId as any).startTime) {
                // Lesson: use schedule times
                const schedule = booking.scheduleId as any;
                bookingStart = new Date(schedule.startTime);
                bookingEnd = new Date(schedule.endTime);
            } else {
                return;
            }

            // Check if time ranges overlap
            const overlaps =
                (startTime >= bookingStart && startTime < bookingEnd) ||
                (endTime > bookingStart && endTime <= bookingEnd) ||
                (startTime <= bookingStart && endTime >= bookingEnd);

            if (overlaps) {
                occupiedCourtIds.add(booking.courtId.toString());
            }
        });

        // Find first available court
        for (const court of courts) {
            if (!occupiedCourtIds.has(court._id.toString())) {
                return { _id: court._id, name: court.name };
            }
        }

        return null;
    }
}

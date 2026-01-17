import { Types } from 'mongoose';
import { BookingModel, BookingDocument } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { TenantService } from './TenantService';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'BookingService' });

export interface CreateBookingData {
    tenantId: string | Types.ObjectId;
    scheduleId?: string | Types.ObjectId; // Optional for court_rental
    studentId: string | Types.ObjectId;
    serviceType: 'individual_class' | 'group_class' | 'court_rental';
    price: number;
    // New fields for court rental
    courtId?: string | Types.ObjectId;
    startTime?: Date;
    endTime?: Date;
}

export class BookingService {
    private tenantService = new TenantService();

    /**
     * Checks if a court is available for a given time range.
     */
    async checkCourtConflict(tenantId: Types.ObjectId, courtId: Types.ObjectId, startTime: Date, endTime: Date): Promise<boolean> {
        // Let's refine the conflict check to be more robust
        const bookings = await BookingModel.find({
            tenantId,
            courtId,
            status: { $in: ['confirmed', 'pending'] }
        });

        for (const b of bookings) {
            const bStart = b.bookingDate;
            if (!bStart) continue;

            // Assume 1 hour for rentals if context is missing, 
            // but for court_rental we know the requested range.
            const bEnd = new Date(bStart.getTime() + 60 * 60 * 1000);

            if (startTime < bEnd && endTime > bStart) {
                return true; // Conflict found
            }
        }

        return false;
    }

    /**
     * Creates a booking and updates the schedule/court status.
     * Centralized logic to be used by controllers and webhooks.
     */
    async createBooking(data: CreateBookingData): Promise<BookingDocument> {
        const { tenantId, scheduleId, studentId, serviceType, price, courtId, startTime, endTime } = data;

        try {
            // 1. Get student and check balance
            const student = await StudentModel.findById(studentId);
            if (!student) {
                throw new Error('Estudiante no encontrado');
            }

            if (student.balance < price) {
                throw new Error('Saldo insuficiente para realizar esta reserva');
            }

            let finalCourtId: Types.ObjectId | undefined;
            let professorId: Types.ObjectId | undefined;
            let bookingStartTime: Date;

            if (serviceType === 'court_rental') {
                // 2. Court Rental Logic
                if (!courtId || !startTime || !endTime) {
                    throw new Error('courtId, startTime y endTime son requeridos para arrendamiento de cancha');
                }

                const court = await CourtModel.findById(courtId);
                if (!court || !court.isActive) {
                    throw new Error('Cancha no encontrada o no está activa');
                }

                // Check for conflicts
                const hasConflict = await this.checkCourtConflict(
                    new Types.ObjectId(tenantId.toString()),
                    new Types.ObjectId(courtId.toString()),
                    startTime,
                    endTime
                );

                if (hasConflict) {
                    throw new Error('El horario seleccionado para esta cancha ya está ocupado');
                }

                finalCourtId = new Types.ObjectId(courtId.toString());
                bookingStartTime = startTime;

            } else {
                // 3. Lesson Logic
                if (!scheduleId) {
                    throw new Error('scheduleId es requerido para clases');
                }

                const schedule = await ScheduleModel.findById(scheduleId);
                if (!schedule || !schedule.isAvailable) {
                    throw new Error('El horario ya no está disponible');
                }

                // Update schedule status
                schedule.isAvailable = false;
                schedule.status = 'confirmed';
                schedule.studentId = new Types.ObjectId(studentId.toString());
                await schedule.save();

                finalCourtId = schedule.courtId;
                professorId = schedule.professorId;
                bookingStartTime = schedule.date;
            }

            // 4. Ensure StudentTenant relationship exists
            await this.tenantService.addStudentToTenant(studentId.toString(), tenantId.toString());

            // 5. Create the booking record
            const bookingData: any = {
                tenantId: new Types.ObjectId(tenantId.toString()),
                studentId: new Types.ObjectId(studentId.toString()),
                courtId: finalCourtId,
                serviceType: serviceType,
                price: price,
                status: 'confirmed',
                notes: `Reserva de ${serviceType}`,
                bookingDate: bookingStartTime
            };

            if (scheduleId) bookingData.scheduleId = new Types.ObjectId(scheduleId.toString());
            if (professorId) bookingData.professorId = professorId;

            const booking = await BookingModel.create(bookingData);

            // 6. Deduct balance from student
            await StudentModel.findByIdAndUpdate(studentId, {
                $inc: { balance: -price }
            });

            logger.info('Booking created and balance deducted successfully', {
                bookingId: booking._id.toString(),
                serviceType,
                studentId: studentId.toString(),
                price: price
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

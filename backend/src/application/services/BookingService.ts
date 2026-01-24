import { Types } from 'mongoose';
import { BookingModel, BookingDocument } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
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
     * Verifies both Bookings and Schedules.
     */
    async isCourtAvailable(
        tenantId: Types.ObjectId,
        courtId: Types.ObjectId,
        startTime: Date,
        endTime: Date,
        excludeScheduleId?: Types.ObjectId
    ): Promise<boolean> {
        // 1. Check for Bookings that overlap
        const conflictingBooking = await BookingModel.findOne({
            tenantId,
            courtId,
            status: { $in: ['confirmed', 'pending'] },
            $or: [
                { bookingDate: { $lt: endTime }, endTime: { $gt: startTime } },
                // Fallback for old bookings without endTime
                {
                    $and: [
                        { endTime: { $exists: false } },
                        { bookingDate: { $lt: endTime, $gte: new Date(startTime.getTime() - 60 * 60 * 1000) } }
                    ]
                }
            ]
        });

        if (conflictingBooking) {
            logger.info('Court conflict found in Bookings', { courtId, startTime, endTime, bookingId: conflictingBooking._id });
            return false;
        }

        // 2. Check for Schedules that overlap
        const scheduleQuery: any = {
            tenantId,
            courtId,
            status: { $in: ['confirmed', 'pending'] },
            isBlocked: { $ne: true },
            $or: [
                { startTime: { $lt: endTime }, endTime: { $gt: startTime } }
            ]
        };

        if (excludeScheduleId) {
            scheduleQuery._id = { $ne: excludeScheduleId };
        }

        const conflictingSchedule = await ScheduleModel.findOne(scheduleQuery);

        if (conflictingSchedule) {
            logger.info('Court conflict found in Schedules', { courtId, startTime, endTime, scheduleId: conflictingSchedule._id });
            return false;
        }

        return true;
    }

    /**
     * Backward compatibility wrapper for checkCourtConflict
     */
    async checkCourtConflict(tenantId: Types.ObjectId, courtId: Types.ObjectId, startTime: Date, endTime: Date): Promise<boolean> {
        const available = await this.isCourtAvailable(tenantId, courtId, startTime, endTime);
        return !available; // returns true if there IS a conflict
    }

    /**
     * Creates a booking and updates the schedule/court status.
     * Centralized logic to be used by controllers and webhooks.
     */
    async createBooking(data: CreateBookingData): Promise<BookingDocument> {
        const { tenantId, scheduleId, studentId, serviceType, price, courtId, startTime, endTime } = data;
        const tenant = await this.tenantService.getTenantById(tenantId.toString());

        try {
            // 1. Get student and check balance in THIS tenant
            const student = await StudentModel.findById(studentId);
            if (!student) {
                throw new Error('Estudiante no encontrado');
            }

            const studentTenant = await StudentTenantModel.findOne({
                studentId: new Types.ObjectId(studentId.toString()),
                tenantId: new Types.ObjectId(tenantId.toString())
            });

            const currentBalance = studentTenant?.balance || 0;

            if (tenant?.config?.payments?.enableOnlinePayments) {
                if (currentBalance < price) {
                    throw new Error('Saldo insuficiente en este centro para realizar esta reserva');
                }
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
                bookingDate: bookingStartTime,
                endTime: serviceType === 'court_rental' ? endTime : undefined
            };

            if (serviceType !== 'court_rental' && scheduleId) {
                const schedule = await ScheduleModel.findById(scheduleId);
                if (schedule) {
                    bookingData.endTime = schedule.endTime;
                }
            }

            if (scheduleId) bookingData.scheduleId = new Types.ObjectId(scheduleId.toString());
            if (professorId) bookingData.professorId = professorId;

            const booking = await BookingModel.create(bookingData);

            // 6. ALWAYS deduct balance from StudentTenant (creates debt)
            await StudentTenantModel.findOneAndUpdate(
                {
                    studentId: new Types.ObjectId(studentId.toString()),
                    tenantId: new Types.ObjectId(tenantId.toString())
                },
                {
                    $inc: { balance: -price },
                    $setOnInsert: { isActive: true, joinedAt: new Date() }
                },
                { upsert: true, new: true }
            );

            // Check if online payments are enabled
            const enableOnlinePayments = tenant?.config?.payments?.enableOnlinePayments === true;

            if (enableOnlinePayments) {
                logger.info('Booking created and balance deducted', {
                    bookingId: booking._id.toString(),
                    serviceType,
                    price
                });
            } else {
                logger.info('Booking created - payment pending', {
                    bookingId: booking._id.toString(),
                    serviceType,
                    price
                });
            }

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

        for (const court of courts) {
            const isAvailable = await this.isCourtAvailable(
                tenantId,
                court._id,
                startTime,
                endTime
            );
            if (isAvailable) {
                return { _id: court._id, name: court.name };
            }
        }

        return null;
    }
}

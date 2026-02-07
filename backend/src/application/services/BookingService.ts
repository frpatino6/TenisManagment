import { Types } from 'mongoose';
import { BookingModel, BookingDocument } from '../../infrastructure/database/models/BookingModel';
import { ScheduleModel } from '../../infrastructure/database/models/ScheduleModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { ProfessorTenantModel } from '../../infrastructure/database/models/ProfessorTenantModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { TenantService } from './TenantService';
import { BalanceService } from './BalanceService';
import { ScheduleValidationService } from './ScheduleValidationService';
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
    status?: 'pending' | 'confirmed' | 'cancelled' | 'completed';
    // Flag to indicate payment was already processed externally (e.g., Wompi)
    // When true, BookingService will NOT create automatic wallet payment
    paymentAlreadyProcessed?: boolean;
}

export class BookingService {
    private tenantService = new TenantService();
    private balanceService = new BalanceService();

    /**
     * Checks if a court is available for a given time range.
     * Verifies both Bookings and Schedules.
     */
    async isCourtAvailable(
        tenantId: Types.ObjectId,
        courtId: Types.ObjectId,
        startTime: Date,
        endTime: Date,
        excludeScheduleId?: Types.ObjectId,
        excludeBookingId?: Types.ObjectId
    ): Promise<boolean> {
        logger.info('Checking court availability', {
            tenantId: tenantId.toString(),
            courtId: courtId.toString(),
            startTime: startTime.toISOString(),
            endTime: endTime.toISOString(),
            excludeScheduleId: excludeScheduleId?.toString(),
            excludeBookingId: excludeBookingId?.toString()
        });

        const bookingQuery: Record<string, unknown> = {
            tenantId,
            courtId,
            status: { $in: ['confirmed', 'pending'] },
            $or: [
                // Bookings with endTime that overlap
                // bookingDate < requestedEndTime AND bookingEndTime > requestedStartTime
                {
                    bookingDate: { $lt: endTime },
                    endTime: { $gt: startTime }
                },
                // Fallback for old bookings without endTime (assume 1 hour duration)
                // bookingDate < requestedEndTime AND (bookingDate + 1 hour) > requestedStartTime
                // Which is: bookingDate < requestedEndTime AND bookingDate > (requestedStartTime - 1 hour)
                {
                    $and: [
                        { endTime: { $exists: false } },
                        { bookingDate: { $lt: endTime } },
                        { bookingDate: { $gt: new Date(startTime.getTime() - 60 * 60 * 1000) } }
                    ]
                }
            ]
        };
        if (excludeBookingId) {
            bookingQuery._id = { $ne: excludeBookingId };
        }

        const conflictingBooking = await BookingModel.findOne(bookingQuery as any);

        if (conflictingBooking) {
            logger.info('Court conflict found in Bookings', { 
                courtId: courtId.toString(), 
                startTime: startTime.toISOString(), 
                endTime: endTime.toISOString(), 
                bookingId: conflictingBooking._id.toString(),
                conflictingBookingDate: conflictingBooking.bookingDate?.toISOString(),
                conflictingEndTime: conflictingBooking.endTime?.toISOString(),
                conflictingStatus: conflictingBooking.status,
                conflictingServiceType: conflictingBooking.serviceType,
                conflictingTenantId: conflictingBooking.tenantId?.toString()
            });
            return false;
        }

        // 2. Check for Schedules that overlap AND are actually occupied
        // A Schedule only blocks the court if:
        // - It's blocked (isBlocked: true), OR
        // - It's not available (isAvailable: false), OR
        // - It has a student assigned (studentId exists)
        const scheduleQuery: any = {
            tenantId,
            courtId,
            status: { $in: ['confirmed', 'pending'] },
            $or: [
                { isBlocked: true },
                { isAvailable: false },
                { studentId: { $exists: true, $ne: null } }
            ],
            $and: [
                { startTime: { $lt: endTime } },
                { endTime: { $gt: startTime } }
            ]
        };

        if (excludeScheduleId) {
            scheduleQuery._id = { $ne: excludeScheduleId };
        }

        const conflictingSchedule = await ScheduleModel.findOne(scheduleQuery);

        if (conflictingSchedule) {
            logger.info('Court conflict found in Schedules', { 
                courtId: courtId.toString(), 
                startTime: startTime.toISOString(), 
                endTime: endTime.toISOString(), 
                scheduleId: conflictingSchedule._id.toString(),
                scheduleStartTime: conflictingSchedule.startTime?.toISOString(),
                scheduleEndTime: conflictingSchedule.endTime?.toISOString(),
                isAvailable: conflictingSchedule.isAvailable,
                isBlocked: conflictingSchedule.isBlocked,
                hasStudentId: !!conflictingSchedule.studentId,
                scheduleStatus: conflictingSchedule.status
            });
            return false;
        }

        logger.info('Court is available', {
            tenantId: tenantId.toString(),
            courtId: courtId.toString(),
            startTime: startTime.toISOString(),
            endTime: endTime.toISOString()
        });

        return true;
    }

    /**
     * Checks availability for multiple court slots in batch
     * Returns a map of slot index to availability status
     */
    async areCourtsAvailableBatch(
        tenantId: Types.ObjectId,
        slots: Array<{ courtId: Types.ObjectId; startTime: Date; endTime: Date }>
    ): Promise<Map<number, boolean>> {
        logger.info('Checking court availability in batch', {
            tenantId: tenantId.toString(),
            slotCount: slots.length
        });

        const availabilityMap = new Map<number, boolean>();
        
        // Initialize all slots as available
        slots.forEach((_, index) => availabilityMap.set(index, true));

        if (slots.length === 0) {
            return availabilityMap;
        }

        // Group slots by courtId for efficient querying
        const slotsByCourt = new Map<string, Array<{ index: number; startTime: Date; endTime: Date }>>();
        slots.forEach((slot, index) => {
            const courtIdStr = slot.courtId.toString();
            if (!slotsByCourt.has(courtIdStr)) {
                slotsByCourt.set(courtIdStr, []);
            }
            slotsByCourt.get(courtIdStr)!.push({ index, startTime: slot.startTime, endTime: slot.endTime });
        });

        // Process each court's slots
        for (const [courtIdStr, courtSlots] of slotsByCourt.entries()) {
            const courtId = new Types.ObjectId(courtIdStr);
            
            // Find earliest start and latest end for this court's slots
            const earliestStart = new Date(Math.min(...courtSlots.map(s => s.startTime.getTime())));
            const latestEnd = new Date(Math.max(...courtSlots.map(s => s.endTime.getTime())));

            // 1. Check for Bookings that overlap with any slot
            const conflictingBookings = await BookingModel.find({
                tenantId,
                courtId,
                status: { $in: ['confirmed', 'pending'] },
                $or: [
                    // Bookings with endTime that overlap
                    {
                        bookingDate: { $lt: latestEnd },
                        endTime: { $gt: earliestStart }
                    },
                    // Fallback for old bookings without endTime
                    {
                        $and: [
                            { endTime: { $exists: false } },
                            { bookingDate: { $lt: latestEnd } },
                            { bookingDate: { $gt: new Date(earliestStart.getTime() - 60 * 60 * 1000) } }
                        ]
                    }
                ]
            });

            // Check each slot against conflicting bookings
            for (const slot of courtSlots) {
                const hasBookingConflict = conflictingBookings.some(booking => {
                    const bookingStart = booking.bookingDate;
                    if (!bookingStart) return false;
                    const bookingEnd = booking.endTime || new Date(bookingStart.getTime() + 60 * 60 * 1000);
                    return bookingStart < slot.endTime && bookingEnd > slot.startTime;
                });

                if (hasBookingConflict) {
                    availabilityMap.set(slot.index, false);
                    continue;
                }
            }

            // 2. Check for Schedules that overlap with any slot
            const conflictingSchedules = await ScheduleModel.find({
                tenantId,
                courtId,
                status: { $in: ['confirmed', 'pending'] },
                $or: [
                    { isBlocked: true },
                    { isAvailable: false },
                    { studentId: { $exists: true, $ne: null } }
                ],
                $and: [
                    { startTime: { $lt: latestEnd } },
                    { endTime: { $gt: earliestStart } }
                ]
            });

            // Check each slot against conflicting schedules
            for (const slot of courtSlots) {
                if (availabilityMap.get(slot.index) === false) {
                    continue; // Already marked as unavailable
                }

                const hasScheduleConflict = conflictingSchedules.some(schedule => {
                    return schedule.startTime < slot.endTime && schedule.endTime > slot.startTime;
                });

                if (hasScheduleConflict) {
                    availabilityMap.set(slot.index, false);
                }
            }
        }

        logger.info('Court availability batch check completed', {
            tenantId: tenantId.toString(),
            totalSlots: slots.length,
            availableSlots: Array.from(availabilityMap.values()).filter(v => v).length,
            unavailableSlots: Array.from(availabilityMap.values()).filter(v => !v).length
        });

        return availabilityMap;
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
        const { tenantId, scheduleId, studentId, serviceType, price, courtId, startTime, endTime, paymentAlreadyProcessed } = data;
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

                // Validate that schedule doesn't have conflict with court_rental booking
                if (schedule.courtId) {
                    const scheduleValidationService = new ScheduleValidationService();
                    const hasConflict = await scheduleValidationService.hasCourtRentalConflict(
                        schedule,
                        new Types.ObjectId(tenantId.toString())
                    );

                    if (hasConflict) {
                        throw new Error('El horario seleccionado no está disponible debido a un alquiler de cancha');
                    }
                }

                // Update schedule status
                schedule.isAvailable = false;
                schedule.status = data.status || 'pending';
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
                status: data.status || 'pending',
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
            // Get balance BEFORE deduction to check if it was sufficient
            const balanceBeforeDeduction = currentBalance;
            const wasPaidWithBalance = balanceBeforeDeduction >= price;

            const updatedStudentTenant = await StudentTenantModel.findOneAndUpdate(
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

            // 7. If balance was sufficient AND online payments are enabled, create Payment automatically
            // This tracks that booking was paid with balance and prevents double-counting when admin confirms
            // Only create Payment if online payments are enabled (otherwise it's payment to professor)
            // IMPORTANT: Do NOT create wallet payment if payment was already processed externally (e.g., Wompi)
            const enableOnlinePayments = tenant?.config?.payments?.enableOnlinePayments === true;
            
            // CRITICAL: Check if a payment already exists for this booking (e.g., from Wompi webhook)
            // This prevents creating duplicate payments when booking is created after Wompi payment
            // Check for ANY paid payment (wallet, card, etc.)
            const existingPayment = await PaymentModel.findOne({
                bookingId: booking._id,
                status: 'paid'
            });
            
            // Also check if there's a card payment (Wompi) that might be linked to this booking
            // This handles the case where webhook created payment before booking was created
            const existingCardPayment = await PaymentModel.findOne({
                bookingId: booking._id,
                method: 'card',
                isOnline: true,
                status: 'paid'
            });
            
            // SOLUCIÓN ESCENARIO 4: Si no hay payment vinculado, buscar payment reciente sin bookingId
            // que coincida con este booking (mismo estudiante, tenant, monto)
            // Esto maneja el caso donde el usuario pagó con Wompi SIN bookingInfo,
            // el webhook creó "Recarga de Saldo", y ahora se crea el booking
            let paymentToLink = null;
            if (!existingPayment && !existingCardPayment && wasPaidWithBalance && enableOnlinePayments && !paymentAlreadyProcessed) {
                const fiveMinutesAgo = new Date(Date.now() - 5 * 60 * 1000);
                paymentToLink = await PaymentModel.findOne({
                    studentId: new Types.ObjectId(studentId.toString()),
                    tenantId: new Types.ObjectId(tenantId.toString()),
                    amount: price,
                    bookingId: null, // Payment sin booking (fue creado como "Recarga de Saldo")
                    method: 'card',
                    isOnline: true,
                    status: 'paid',
                    createdAt: { $gte: fiveMinutesAgo } // Últimos 5 minutos
                }).sort({ createdAt: -1 }); // Más reciente primero
                
                if (paymentToLink) {
                    // Vincular el payment al booking en lugar de crear uno nuevo
                    paymentToLink.bookingId = booking._id;
                    paymentToLink.description = `Pago Wompi para reserva: ${serviceType}`;
                    paymentToLink.concept = `Reserva ${serviceType}`;
                    if (professorId) {
                        paymentToLink.professorId = new Types.ObjectId(professorId.toString());
                    }
                    await paymentToLink.save();
                    
                    logger.info('Payment reciente vinculado al booking en lugar de crear wallet payment', {
                        bookingId: booking._id.toString(),
                        paymentId: paymentToLink._id.toString(),
                        amount: price,
                        serviceType
                    });
                }
            }
            
            if (wasPaidWithBalance && enableOnlinePayments && !paymentAlreadyProcessed && !existingPayment && !existingCardPayment && !paymentToLink) {
                await PaymentModel.create({
                    tenantId: new Types.ObjectId(tenantId.toString()),
                    studentId: new Types.ObjectId(studentId.toString()),
                    professorId: professorId || undefined,
                    bookingId: booking._id,
                    amount: price,
                    date: new Date(),
                    status: 'paid',
                    method: 'wallet',
                    description: `Pago con saldo: ${serviceType}`,
                    concept: `Reserva ${serviceType}`,
                    isOnline: false
                });

                logger.info('Payment created automatically for booking paid with balance', {
                    bookingId: booking._id.toString(),
                    amount: price,
                    serviceType,
                    balanceBefore: balanceBeforeDeduction
                });
            } else if (existingPayment) {
                logger.info('Skipping wallet payment creation - payment already exists for booking', {
                    bookingId: booking._id.toString(),
                    existingPaymentId: existingPayment._id.toString(),
                    existingPaymentMethod: existingPayment.method
                });
            }

            // Sincronizar el balance después de crear el booking y cualquier payment
            await this.balanceService.syncBalance(
                new Types.ObjectId(studentId.toString()),
                new Types.ObjectId(tenantId.toString())
            );

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

    async rescheduleBooking(
        tenantId: Types.ObjectId,
        bookingId: Types.ObjectId,
        newStartTime: Date,
        newEndTime: Date
    ): Promise<BookingDocument> {
        const booking = await BookingModel.findOne({
            _id: bookingId,
            tenantId,
            status: { $in: ['confirmed', 'pending'] },
        });

        if (!booking) {
            throw new Error('Reserva no encontrada');
        }

        if (booking.serviceType !== 'court_rental' || !booking.courtId) {
            throw new Error('Solo se pueden reprogramar reservas de cancha');
        }

        const available = await this.isCourtAvailable(
            tenantId,
            booking.courtId as Types.ObjectId,
            newStartTime,
            newEndTime,
            undefined,
            bookingId
        );

        if (!available) {
            throw new Error('El horario seleccionado ya está ocupado');
        }

        booking.bookingDate = newStartTime;
        booking.endTime = newEndTime;
        await booking.save();

        return booking;
    }
}

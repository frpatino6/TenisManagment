import { Request, Response } from 'express';
import { Types } from 'mongoose';
import { z } from 'zod';
import { PaymentGateway } from '../../domain/services/payment/PaymentGateway';
import { WompiAdapter } from '../../infrastructure/services/payment/adapters/WompiAdapter';
import { TransactionModel } from '../../infrastructure/database/models/TransactionModel';
import { TenantModel, TenantDocument } from '../../infrastructure/database/models/TenantModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { AuthUserModel, UserRole } from '../../infrastructure/database/models/AuthUserModel';
import { TenantService } from '../services/TenantService';
import { BookingService } from '../services/BookingService';
import { BalanceService } from '../services/BalanceService';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { Logger } from '../../infrastructure/services/Logger';

interface AuthenticatedRequest extends Request {
    user?: {
        id: string;
        role: UserRole;
        uid?: string;
        email?: string;
    };
    tenantId?: string;
}

export class PaymentController {
    private paymentGateway: PaymentGateway;
    private logger = new Logger();
    private tenantService = new TenantService();
    private bookingService = new BookingService();
    private balanceService = new BalanceService();

    constructor(paymentGateway: PaymentGateway) {
        this.paymentGateway = paymentGateway;
    }

    /**
     * Inicia una transacción de pago
     * POST /api/payments/init
     */
    public initPayment = async (req: AuthenticatedRequest, res: Response) => {
        try {
            const schema = z.object({
                amount: z.number().min(1000, 'El monto mínimo es 1000'),
                currency: z.enum(['COP']).default('COP'),
                bookingInfo: z.object({
                    scheduleId: z.string(),
                    serviceType: z.enum(['individual_class', 'group_class', 'court_rental']),
                    price: z.number()
                }).optional(),
                redirectUrl: z.string().url().optional(),
            });

            const { amount, currency, bookingInfo, redirectUrl } = schema.parse(req.body);

            // req.user is populated by authMiddleware { id, role }
            const userId = req.user?.id;
            const tenantId = req.tenantId;

            if (!userId || !tenantId) {
                return res.status(401).json({ error: 'Usuario no autenticado o Tenant no identificado' });
            }

            // Fetch full User and Tenant documents
            const user = await AuthUserModel.findById(userId);
            const tenant = await TenantModel.findById(tenantId);

            if (!user) {
                return res.status(404).json({ error: 'Usuario no encontrado' });
            }
            if (!tenant) {
                return res.status(404).json({ error: 'Tenant no encontrado' });
            }

            // Buscar el estudiante para obtener su ID real
            let studentId: any = user.linkedId;

            if (user.role === 'student') {
                const student = await StudentModel.findOne({ authUserId: user._id });
                if (student) {
                    studentId = student._id;
                } else {
                    this.logger.error('[PaymentController] Student profile not found for user', { userId: user._id });
                    return res.status(404).json({ error: 'Perfil de estudiante no encontrado' });
                }
            } else if (!studentId) {
                // Si no es estudiante y no tiene linkedId, no podemos procesar (por ahora pagos son solo de estudiantes)
                return res.status(400).json({ error: 'El usuario no tiene un perfil de estudiante válido para realizar pagos.' });
            }

            // Verificar si los pagos online están habilitados para este tenant
            if (!tenant.config?.payments?.enableOnlinePayments) {
                return res.status(403).json({
                    error: 'Los pagos online están deshabilitados para este centro.',
                    code: 'ONLINE_PAYMENTS_DISABLED'
                });
            }

            // 1. Crear Intent en el Gateway (Wompi)
            const intent = await this.paymentGateway.createPaymentIntent(amount, currency, user, tenant, { redirectUrl });

            // 2. Transacción
            const transaction = new TransactionModel({
                tenantId: tenant._id,
                studentId: studentId,
                reference: intent.reference,
                externalId: intent.externalId,
                amount: amount,
                currency: currency,
                status: 'PENDING',
                gateway: 'WOMPI',
                metadata: {
                    initialResponse: intent,
                    bookingInfo: bookingInfo
                }
            });

            await transaction.save();

            this.logger.info(`[PaymentController] Init Payment ${intent.reference} for user ${user.email}`);

            return res.status(200).json(intent);

        } catch (error: any) {
            this.logger.error('[PaymentController] Error init payment', {
                message: error.message,
                stack: error.stack,
                details: error
            });
            if (error instanceof z.ZodError) {
                return res.status(400).json({ error: error.errors });
            }
            return res.status(500).json({ error: 'Error interno al iniciar pago', details: error.message });
        }
    };

    /**
     * Recibe notificaciones de Wompi
     * POST /api/payments/webhooks/wompi
     */
    public wompiWebhook = async (req: Request, res: Response) => {
        try {
            const data = req.body;
            const transactionData = data?.data?.transaction;

            if (!transactionData) {
                this.logger.warn('[PaymentController] Webhook received without transaction data');
                return res.status(200).type('text/plain').send('OK');
            }

            const reference = transactionData.reference;

            const transaction = await TransactionModel.findOne({ reference });
            if (!transaction) {
                this.logger.warn(`[PaymentController] Transaction not found for ref: ${reference}`);
                return res.status(200).type('text/plain').send('OK');
            }

            // Re-fetch tenant to ensure we have the document with config
            const tenant = await TenantModel.findById(transaction.tenantId);
            if (!tenant) {
                this.logger.warn(`[PaymentController] Tenant missing for transaction: ${reference}`);
                return res.status(200).type('text/plain').send('OK');
            }

            const result = await this.paymentGateway.validateTransaction(data, tenant);

            transaction.status = result.status;
            transaction.externalId = result.externalId;
            transaction.customerEmail = result.customerEmail;
            transaction.paymentMethodType = result.paymentMethodType;
            transaction.updatedAt = new Date();
            transaction.metadata = { ...transaction.metadata, webhookEvent: data };
            await transaction.save();

            if (result.status === 'APPROVED' && !isNaN(result.amount) && result.amount > 0) {
                const existingPayment = await PaymentModel.findOne({
                    $or: [
                        { externalReference: reference },
                        { description: { $regex: reference } }
                    ]
                });

                if (!existingPayment) {
                    // Check if this is a payment for a booking or a recharge
                    const hasBookingInfo = transaction.metadata?.bookingInfo;

                    if (hasBookingInfo) {
                        // This is a payment for a booking, not a recharge
                        // Check if booking already exists (e.g., created from mobile with wallet payment)
                        const bInfo = transaction.metadata.bookingInfo;

                        // Try to find existing booking by scheduleId or courtId + time
                        let existingBooking = null;
                        if (bInfo.scheduleId) {
                            existingBooking = await BookingModel.findOne({
                                scheduleId: new Types.ObjectId(bInfo.scheduleId),
                                studentId: transaction.studentId,
                                tenantId: transaction.tenantId,
                                status: { $in: ['pending', 'confirmed'] }
                            });
                        } else if (bInfo.courtId && bInfo.startTime) {
                            existingBooking = await BookingModel.findOne({
                                courtId: new Types.ObjectId(bInfo.courtId),
                                studentId: transaction.studentId,
                                tenantId: transaction.tenantId,
                                bookingDate: new Date(bInfo.startTime),
                                status: { $in: ['pending', 'confirmed'] }
                            });
                        }

                        if (existingBooking) {
                            // Booking already exists, check if it has a wallet payment that needs to be replaced
                            this.logger.info(`[PaymentController] Booking already exists, checking for existing payments for ref: ${reference}`);

                            // Find existing wallet payment (created when booking was made from mobile)
                            const existingWalletPayment = await PaymentModel.findOne({
                                bookingId: existingBooking._id,
                                method: 'wallet',
                                status: 'paid'
                            });

                            if (existingWalletPayment) {
                                // Delete the wallet payment since we're paying with card now
                                this.logger.info(`[PaymentController] Removing wallet payment and creating card payment for ref: ${reference}`, {
                                    walletPaymentId: existingWalletPayment._id.toString()
                                });
                                await PaymentModel.deleteOne({ _id: existingWalletPayment._id });
                            }

                            // Check if card payment already exists (prevent duplicates)
                            const existingCardPayment = await PaymentModel.findOne({
                                bookingId: existingBooking._id,
                                method: 'card',
                                externalReference: reference
                            });

                            if (!existingCardPayment) {
                                // Create the card payment
                                const newPayment = new PaymentModel({
                                    tenantId: tenant._id,
                                    studentId: transaction.studentId,
                                    professorId: bInfo.professorId ? new Types.ObjectId(bInfo.professorId) : null,
                                    bookingId: existingBooking._id,
                                    amount: result.amount,
                                    date: new Date(),
                                    status: 'paid',
                                    method: 'card',
                                    description: `Pago Wompi para reserva: ${bInfo.serviceType} Ref: ${reference}`,
                                    concept: `Reserva ${bInfo.serviceType}`,
                                    externalReference: reference,
                                    isOnline: true
                                });
                                await newPayment.save();
                                await this.balanceService.syncBalance(transaction.studentId, tenant._id);
                                this.logger.info(`[PaymentController] Card payment created for existing booking ref: ${reference}`);
                            } else {
                                this.logger.info(`[PaymentController] Card payment already exists for ref: ${reference}, skipping`);
                            }
                        } else {
                            // Booking doesn't exist, create it
                            try {
                                this.logger.info(`[PaymentController] Auto-booking for ref: ${reference}`);
                                const booking = await this.bookingService.createBooking({
                                    tenantId: transaction.tenantId.toString(),
                                    studentId: transaction.studentId.toString(),
                                    scheduleId: bInfo.scheduleId,
                                    serviceType: bInfo.serviceType,
                                    price: bInfo.price,
                                    status: 'confirmed',
                                    // Pass court rental fields if present in metadata
                                    courtId: bInfo.courtId,
                                    startTime: bInfo.startTime ? new Date(bInfo.startTime) : undefined,
                                    endTime: bInfo.endTime ? new Date(bInfo.endTime) : undefined,
                                    // Payment already processed by Wompi, don't create wallet payment
                                    paymentAlreadyProcessed: true
                                });

                                // Create payment linked to the booking
                                const newPayment = new PaymentModel({
                                    tenantId: tenant._id,
                                    studentId: transaction.studentId,
                                    professorId: bInfo.professorId ? new Types.ObjectId(bInfo.professorId) : null,
                                    bookingId: booking._id,
                                    amount: result.amount,
                                    date: new Date(),
                                    status: 'paid',
                                    method: 'card',
                                    description: `Pago Wompi para reserva: ${bInfo.serviceType} Ref: ${reference}`,
                                    concept: `Reserva ${bInfo.serviceType}`,
                                    externalReference: reference,
                                    isOnline: true
                                });
                                await newPayment.save();

                                // Sincronizar el balance después de crear el Payment y Booking
                                await this.balanceService.syncBalance(transaction.studentId, tenant._id);

                                this.logger.info(`[PaymentController] Auto-booking SUCCESS for ref: ${reference}`);
                            } catch (bookingError: any) {
                                this.logger.error(`[PaymentController] Auto-booking FAILED for ref: ${reference}`, {
                                    error: bookingError.message
                                });
                                // If booking creation fails, create as recharge so user can retry
                                const newPayment = new PaymentModel({
                                    tenantId: tenant._id,
                                    studentId: transaction.studentId,
                                    professorId: null,
                                    amount: result.amount,
                                    date: new Date(),
                                    status: 'paid',
                                    method: 'card',
                                    description: `Recarga Wompi Ref: ${reference}`,
                                    concept: 'Recarga de Saldo',
                                    externalReference: reference,
                                    isOnline: true
                                });
                                await newPayment.save();
                                await this.balanceService.syncBalance(transaction.studentId, tenant._id);
                            }
                        }
                    } else {
                        // This appears to be a recharge (no bookingInfo in transaction)
                        // BUT: Check if there's a recent booking without payment that matches this amount
                        // This handles the case where user paid with Wompi but bookingInfo wasn't sent
                        // IMPORTANT: Only match bookings that DON'T have a card payment (to avoid wrong matches)
                        const bookingsWithCardPayments = await PaymentModel.distinct('bookingId', {
                            method: 'card',
                            isOnline: true,
                            status: 'paid',
                            externalReference: { $exists: true, $ne: null }
                        });

                        const recentBooking = await BookingModel.findOne({
                            tenantId: transaction.tenantId,
                            studentId: transaction.studentId,
                            price: result.amount,
                            status: { $in: ['pending', 'confirmed'] },
                            createdAt: { $gte: new Date(Date.now() - 5 * 60 * 1000) }, // Last 5 minutes (reduced from 10)
                            _id: { $nin: bookingsWithCardPayments } // Exclude bookings that already have card payments
                        }).sort({ createdAt: -1 });

                        if (recentBooking) {
                            // Check if booking already has a wallet payment
                            const existingWalletPayment = await PaymentModel.findOne({
                                bookingId: recentBooking._id,
                                method: 'wallet',
                                status: 'paid'
                            });

                            if (existingWalletPayment) {
                                // Delete wallet payment and create card payment
                                this.logger.info(`[PaymentController] Found recent booking with wallet payment, replacing with card payment for ref: ${reference}`);
                                await PaymentModel.deleteOne({ _id: existingWalletPayment._id });
                            }

                            // Check if card payment already exists
                            const existingCardPayment = await PaymentModel.findOne({
                                bookingId: recentBooking._id,
                                method: 'card',
                                externalReference: reference
                            });

                            if (!existingCardPayment) {
                                // Create card payment linked to the booking
                                const newPayment = new PaymentModel({
                                    tenantId: tenant._id,
                                    studentId: transaction.studentId,
                                    professorId: recentBooking.professorId || null,
                                    bookingId: recentBooking._id,
                                    amount: result.amount,
                                    date: new Date(),
                                    status: 'paid',
                                    method: 'card',
                                    description: `Pago Wompi para reserva: ${recentBooking.serviceType} Ref: ${reference}`,
                                    concept: `Reserva ${recentBooking.serviceType}`,
                                    externalReference: reference,
                                    isOnline: true
                                });
                                await newPayment.save();
                                await this.balanceService.syncBalance(transaction.studentId, tenant._id);
                                this.logger.info(`[PaymentController] Payment linked to recent booking for ref: ${reference}`);
                            } else {
                                this.logger.info(`[PaymentController] Card payment already exists for booking, skipping ref: ${reference}`);
                            }
                        } else {
                            // No recent booking found, treat as recharge
                            const newPayment = new PaymentModel({
                                tenantId: tenant._id,
                                studentId: transaction.studentId,
                                professorId: null,
                                amount: result.amount,
                                date: new Date(),
                                status: 'paid',
                                method: 'card',
                                description: `Recarga Wompi Ref: ${reference}`,
                                concept: 'Recarga de Saldo',
                                externalReference: reference,
                                isOnline: true
                                // NO bookingId - this is a recharge
                            });
                            await newPayment.save();

                            // Sincronizar el balance después de crear el Payment
                            await this.balanceService.syncBalance(transaction.studentId, tenant._id);

                            this.logger.info(`[PaymentController] Payment processed as recharge and balance synced for ${reference}`);
                        }
                    }
                }
            }

            return res.status(200).json({ status: 'ok' });

        } catch (error) {
            this.logger.error('[PaymentController] Webhook error', { error });
            return res.status(500).json({ error: 'Internal Error' });
        }
    };

    /**
     * Consulta el estado de una transacción en Wompi.
     *
     * @param req - Request autenticado con tenantId y transactionId en query.
     * @param res - Response HTTP.
     * @returns Estado normalizado de la transacción.
     */
    public getTransactionStatus = async (
        req: AuthenticatedRequest,
        res: Response,
    ) => {
        try {
            const schema = z.object({
                transactionId: z.string().optional(),
                reference: z.string().optional(),
            }).refine(
                (data) => Boolean(data.transactionId || data.reference),
                { message: 'transactionId o reference requerido' },
            );

            const { transactionId, reference } = schema.parse(req.query);
            const tenantId = req.tenantId;

            if (!tenantId) {
                return res.status(401).json({ error: 'Tenant no identificado' });
            }

            const tenant = await TenantModel.findById(tenantId);
            if (!tenant) {
                return res.status(404).json({ error: 'Tenant no encontrado' });
            }

            if (!transactionId && reference) {
                const transaction = await TransactionModel.findOne({
                    tenantId,
                    reference,
                });

                if (!transaction) {
                    return res.status(200).json({ status: 'PENDING', reference });
                }

                return res.status(200).json({
                    status: transaction.status,
                    reference: transaction.reference,
                });
            }

            const result = await this.paymentGateway.getTransactionStatus(
                transactionId as string,
                tenant,
            );

            const transaction =
                (await TransactionModel.findOne({ reference: result.reference })) ||
                (await TransactionModel.findOne({ externalId: result.externalId }));

            if (transaction) {
                transaction.status = result.status;
                transaction.externalId = result.externalId;
                transaction.customerEmail = result.customerEmail;
                transaction.paymentMethodType = result.paymentMethodType;
                transaction.updatedAt = new Date();
                transaction.metadata = { ...transaction.metadata, statusQuery: result.metadata };
                await transaction.save();

                if (result.status === 'APPROVED' && !isNaN(result.amount) && result.amount > 0) {
                    const existingPayment = await PaymentModel.findOne({
                        $or: [
                            { externalReference: result.reference },
                            { description: { $regex: result.reference } }
                        ]
                    });

                    if (!existingPayment) {
                        // Check if this is a payment for a booking or a recharge
                        const hasBookingInfo = transaction.metadata?.bookingInfo;

                        if (hasBookingInfo) {
                            // This is a payment for a booking, not a recharge
                            const bInfo = transaction.metadata.bookingInfo;

                            // Check if booking already exists (e.g., created from mobile with wallet payment)
                            let existingBooking = null;
                            if (bInfo.scheduleId) {
                                existingBooking = await BookingModel.findOne({
                                    scheduleId: new Types.ObjectId(bInfo.scheduleId),
                                    studentId: transaction.studentId,
                                    tenantId: transaction.tenantId,
                                    status: { $in: ['pending', 'confirmed'] }
                                });
                            } else if (bInfo.courtId && bInfo.startTime) {
                                existingBooking = await BookingModel.findOne({
                                    courtId: new Types.ObjectId(bInfo.courtId),
                                    studentId: transaction.studentId,
                                    tenantId: transaction.tenantId,
                                    bookingDate: new Date(bInfo.startTime),
                                    status: { $in: ['pending', 'confirmed'] }
                                });
                            }

                            if (existingBooking) {
                                // Booking already exists, check if it has a wallet payment that needs to be replaced
                                this.logger.info(`[PaymentController] Booking already exists in getTransactionStatus, checking for existing payments for ref: ${result.reference}`);

                                // Find existing wallet payment (created when booking was made from mobile)
                                const existingWalletPayment = await PaymentModel.findOne({
                                    bookingId: existingBooking._id,
                                    method: 'wallet',
                                    status: 'paid'
                                });

                                if (existingWalletPayment) {
                                    // Delete the wallet payment since we're paying with card now
                                    this.logger.info(`[PaymentController] Removing wallet payment and creating card payment for ref: ${result.reference}`, {
                                        walletPaymentId: existingWalletPayment._id.toString()
                                    });
                                    await PaymentModel.deleteOne({ _id: existingWalletPayment._id });
                                }

                                // Check if card payment already exists (prevent duplicates)
                                const existingCardPayment = await PaymentModel.findOne({
                                    bookingId: existingBooking._id,
                                    method: 'card',
                                    externalReference: result.reference
                                });

                                if (!existingCardPayment) {
                                    // Create the card payment
                                    const newPayment = new PaymentModel({
                                        tenantId: transaction.tenantId,
                                        studentId: transaction.studentId,
                                        professorId: bInfo.professorId ? new Types.ObjectId(bInfo.professorId) : null,
                                        bookingId: existingBooking._id,
                                        amount: result.amount,
                                        date: new Date(),
                                        status: 'paid',
                                        method: 'card',
                                        description: `Pago Wompi para reserva: ${bInfo.serviceType} Ref: ${result.reference}`,
                                        concept: `Reserva ${bInfo.serviceType}`,
                                        externalReference: result.reference,
                                        isOnline: true
                                    });
                                    await newPayment.save();
                                    await this.balanceService.syncBalance(transaction.studentId, transaction.tenantId);
                                    this.logger.info(`[PaymentController] Card payment created for existing booking ref: ${result.reference}`);
                                } else {
                                    this.logger.info(`[PaymentController] Card payment already exists for ref: ${result.reference}, skipping`);
                                }
                            } else {
                                // Booking doesn't exist, create it
                                try {
                                    this.logger.info(`[PaymentController] Auto-booking in getTransactionStatus for ref: ${result.reference}`);
                                    const booking = await this.bookingService.createBooking({
                                        tenantId: transaction.tenantId.toString(),
                                        studentId: transaction.studentId.toString(),
                                        scheduleId: bInfo.scheduleId,
                                        serviceType: bInfo.serviceType,
                                        price: bInfo.price,
                                        courtId: bInfo.courtId,
                                        startTime: bInfo.startTime,
                                        endTime: bInfo.endTime,
                                        // Payment already processed by Wompi, don't create wallet payment
                                        paymentAlreadyProcessed: true
                                    });

                                    // Create payment linked to the booking
                                    const newPayment = new PaymentModel({
                                        tenantId: transaction.tenantId,
                                        studentId: transaction.studentId,
                                        professorId: bInfo.professorId ? new Types.ObjectId(bInfo.professorId) : null,
                                        bookingId: booking._id,
                                        amount: result.amount,
                                        date: new Date(),
                                        status: 'paid',
                                        method: 'card',
                                        description: `Pago Wompi para reserva: ${bInfo.serviceType} Ref: ${result.reference}`,
                                        concept: `Reserva ${bInfo.serviceType}`,
                                        externalReference: result.reference,
                                        isOnline: true
                                    });
                                    await newPayment.save();

                                    // Sincronizar el balance después de crear el Payment y Booking
                                    await this.balanceService.syncBalance(transaction.studentId, transaction.tenantId);
                                    this.logger.info(`[PaymentController] Auto-booking SUCCESS in getTransactionStatus for ref: ${result.reference}`);
                                } catch (error) {
                                    this.logger.error('[PaymentController] Auto-booking failed in getTransactionStatus', {
                                        error: error instanceof Error ? error.message : String(error),
                                    });
                                    // If booking creation fails, create as recharge so user can retry
                                    const newPayment = new PaymentModel({
                                        tenantId: transaction.tenantId,
                                        studentId: transaction.studentId,
                                        professorId: null,
                                        amount: result.amount,
                                        date: new Date(),
                                        status: 'paid',
                                        method: 'card',
                                        description: `Recarga Wompi Ref: ${result.reference}`,
                                        concept: 'Recarga de Saldo',
                                        externalReference: result.reference,
                                        isOnline: true
                                    });
                                    await newPayment.save();
                                    await this.balanceService.syncBalance(transaction.studentId, transaction.tenantId);
                                }
                            }
                        } else {
                            // This appears to be a recharge (no bookingInfo in transaction)
                            // BUT: Check if there's a recent booking without payment that matches this amount
                            // This handles the case where user paid with Wompi but bookingInfo wasn't sent
                            // IMPORTANT: Only match bookings that DON'T have a card payment (to avoid wrong matches)
                            const bookingsWithCardPayments = await PaymentModel.distinct('bookingId', {
                                method: 'card',
                                isOnline: true,
                                status: 'paid',
                                externalReference: { $exists: true, $ne: null }
                            });

                            const recentBooking = await BookingModel.findOne({
                                tenantId: transaction.tenantId,
                                studentId: transaction.studentId,
                                price: result.amount,
                                status: { $in: ['pending', 'confirmed'] },
                                createdAt: { $gte: new Date(Date.now() - 5 * 60 * 1000) }, // Last 5 minutes (reduced from 10)
                                _id: { $nin: bookingsWithCardPayments } // Exclude bookings that already have card payments
                            }).sort({ createdAt: -1 });

                            if (recentBooking) {
                                // Check if booking already has a wallet payment
                                const existingWalletPayment = await PaymentModel.findOne({
                                    bookingId: recentBooking._id,
                                    method: 'wallet',
                                    status: 'paid'
                                });

                                if (existingWalletPayment) {
                                    // Delete wallet payment and create card payment
                                    this.logger.info(`[PaymentController] Found recent booking with wallet payment in getTransactionStatus, replacing with card payment for ref: ${result.reference}`);
                                    await PaymentModel.deleteOne({ _id: existingWalletPayment._id });
                                }

                                // Check if card payment already exists
                                const existingCardPayment = await PaymentModel.findOne({
                                    bookingId: recentBooking._id,
                                    method: 'card',
                                    externalReference: result.reference
                                });

                                if (!existingCardPayment) {
                                    // Create card payment linked to the booking
                                    const newPayment = new PaymentModel({
                                        tenantId: transaction.tenantId,
                                        studentId: transaction.studentId,
                                        professorId: recentBooking.professorId || null,
                                        bookingId: recentBooking._id,
                                        amount: result.amount,
                                        date: new Date(),
                                        status: 'paid',
                                        method: 'card',
                                        description: `Pago Wompi para reserva: ${recentBooking.serviceType} Ref: ${result.reference}`,
                                        concept: `Reserva ${recentBooking.serviceType}`,
                                        externalReference: result.reference,
                                        isOnline: true
                                    });
                                    await newPayment.save();
                                    await this.balanceService.syncBalance(transaction.studentId, transaction.tenantId);
                                    this.logger.info(`[PaymentController] Payment linked to recent booking in getTransactionStatus for ref: ${result.reference}`);
                                } else {
                                    this.logger.info(`[PaymentController] Card payment already exists for booking in getTransactionStatus, skipping ref: ${result.reference}`);
                                }
                            } else {
                                // No recent booking found, treat as recharge
                                const newPayment = new PaymentModel({
                                    tenantId: transaction.tenantId,
                                    studentId: transaction.studentId,
                                    professorId: null,
                                    amount: result.amount,
                                    date: new Date(),
                                    status: 'paid',
                                    method: 'card',
                                    description: `Recarga Wompi Ref: ${result.reference}`,
                                    concept: 'Recarga de Saldo',
                                    externalReference: result.reference,
                                    isOnline: true
                                    // NO bookingId - this is a recharge
                                });
                                await newPayment.save();

                                // Sincronizar el balance después de crear el Payment
                                await this.balanceService.syncBalance(transaction.studentId, transaction.tenantId);
                                this.logger.info(`[PaymentController] Payment processed as recharge in getTransactionStatus and balance synced for ${result.reference}`);
                            }
                        }
                    }
                }
            }

            return res.status(200).json({
                status: result.status,
                reference: result.reference,
                customerEmail: result.customerEmail,
                paymentMethodType: result.paymentMethodType,
            });
        } catch (error: any) {
            if (error instanceof z.ZodError) {
                return res.status(400).json({ error: error.errors });
            }
            this.logger.error('[PaymentController] Error getting transaction status', {
                message: error.message,
                stack: error.stack,
            });
            return res.status(500).json({ error: 'Error interno consultando transacción' });
        }
    };
}

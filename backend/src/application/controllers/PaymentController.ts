import { Request, Response } from 'express';
import { z } from 'zod';
import { Logger } from '../../infrastructure/services/Logger';
import { PaymentGateway } from '../../domain/services/payment/PaymentGateway';
import { WompiAdapter } from '../../infrastructure/services/payment/adapters/WompiAdapter';
import { TransactionModel } from '../../infrastructure/database/models/TransactionModel';
import { TenantModel, TenantDocument } from '../../infrastructure/database/models/TenantModel';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { StudentModel } from '../../infrastructure/database/models/StudentModel';
import { AuthUserModel } from '../../infrastructure/database/models/AuthUserModel';

export class PaymentController {
    private logger = new Logger();
    private paymentGateway: PaymentGateway;

    constructor() {
        this.paymentGateway = new WompiAdapter();
    }

    /**
     * Inicia una transacción de pago
     * POST /api/payments/init
     */
    public initPayment = async (req: Request, res: Response) => {
        try {
            const schema = z.object({
                amount: z.number().min(1000, 'El monto mínimo es 1000'),
                currency: z.enum(['COP']).default('COP'),
            });

            const { amount, currency } = schema.parse(req.body);

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

            // 1. Crear Intent en el Gateway (Wompi)
            const intent = await this.paymentGateway.createPaymentIntent(amount, currency, user, tenant);

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
                    initialResponse: intent
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
            console.error('FULL ERROR:', error); // Direct console log for debugging
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
            transaction.updatedAt = new Date();
            transaction.metadata = { ...transaction.metadata, webhookEvent: data };
            await transaction.save();

            if (result.status === 'APPROVED' && !isNaN(result.amount) && result.amount > 0) {
                const existingPayment = await PaymentModel.findOne({
                    description: { $regex: reference }
                });

                if (!existingPayment) {
                    const newPayment = new PaymentModel({
                        tenantId: tenant._id,
                        studentId: transaction.studentId,
                        professorId: null,
                        amount: result.amount,
                        date: new Date(),
                        status: 'paid',
                        method: 'card',
                        description: `Recarga Wompi Ref: ${reference}`,
                        concept: 'Recarga de Saldo'
                    });
                    await newPayment.save();

                    await StudentModel.findByIdAndUpdate(transaction.studentId, {
                        $inc: { balance: result.amount }
                    });

                    this.logger.info(`[PaymentController] Payment processed for ${reference}`);
                }
            }

            return res.status(200).type('text/plain').send('OK');

        } catch (error) {
            this.logger.error('[PaymentController] Webhook error', { error });
            return res.status(500).send('Internal Error');
        }
    };
}

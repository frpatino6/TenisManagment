
import { Request, Response } from 'express';
import { TransactionModel } from '../../infrastructure/database/models/TransactionModel';
import { TenantModel } from '../../infrastructure/database/models/TenantModel';
import { Logger } from '../../infrastructure/services/Logger';
import { createHash } from 'crypto';
import axios from 'axios';
import { config } from '../../infrastructure/config';

export class TestController {
    private logger = new Logger({ service: 'TestController' });

    /**
     * Simula un pago exitoso de Wompi para una transacción pendiente
     * POST /api/test/simulate-wompi-payment
     */
    public simulateWompiPayment = async (req: Request, res: Response) => {
        try {
            const { studentId, reference: providedRef, amount } = req.body;

            this.logger.info('Simulating Wompi payment', { studentId, providedRef, amount });

            // 1. Encontrar la transacción
            let transaction;
            if (providedRef) {
                transaction = await TransactionModel.findOne({ reference: providedRef });
            } else if (studentId) {
                transaction = await TransactionModel.findOne({
                    studentId,
                    status: 'PENDING'
                }).sort({ createdAt: -1 });
            }

            if (!transaction) {
                return res.status(404).json({ error: 'Transacción no encontrada' });
            }

            // 2. Obtener el tenant para el eventsKey
            const tenant = await TenantModel.findById(transaction.tenantId);
            if (!tenant || !tenant.config?.payments?.wompi?.eventsKey) {
                return res.status(400).json({ error: 'Tenant o Wompi eventsKey no configurado' });
            }

            const eventsKey = tenant.config.payments.wompi.eventsKey;
            const ref = transaction.reference;
            const amountCents = (amount || transaction.amount) * 100;
            const externalId = `SIM-${Date.now()}`;
            const timestamp = Date.now();
            const status = 'APPROVED';

            // 3. Calcular firma (id + status + amount_in_cents + timestamp + eventsKey)
            const rawString = `${externalId}${status}${amountCents}${timestamp}${eventsKey}`;
            const checksum = createHash('sha256').update(rawString).digest('hex');

            // 4. Construir el payload de Wompi
            const wompiPayload = {
                event: 'transaction.updated',
                data: {
                    transaction: {
                        id: externalId,
                        status: status,
                        reference: ref,
                        amount_in_cents: amountCents,
                        currency: 'COP',
                        payment_method_type: 'CARD',
                        customer_email: 'test@example.com'
                    }
                },
                timestamp: timestamp,
                sent_at: new Date().toISOString(),
                signature: {
                    properties: ['transaction.id', 'transaction.status', 'transaction.amount_in_cents', 'timestamp'],
                    checksum: checksum
                }
            };

            // 5. Llamar al webhook real del backend (a través de HTTP para que pase por el router)
            // Usamos localhost:PORT para llamar al endpoint propio
            const port = process.env.PORT || 3000;
            const webhookUrl = `http://localhost:${port}/api/payments/webhooks/wompi`;

            this.logger.info('Sending fake webhook to:', { webhookUrl });

            const response = await axios.post(webhookUrl, wompiPayload);

            return res.status(200).json({
                message: 'Simulación enviada exitosamente',
                webhookResponse: response.data,
                transactionRef: ref
            });

        } catch (error: any) {
            this.logger.error('Error in simulateWompiPayment', { error: error.message });
            return res.status(500).json({ error: error.message });
        }
    }
}

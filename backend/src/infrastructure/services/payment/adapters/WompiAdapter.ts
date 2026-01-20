import { createHash } from 'crypto';
import { PaymentGateway, PaymentIntent, PaymentResult } from '../../../../domain/services/payment/PaymentGateway';
import { AuthUserDocument } from '../../../database/models/AuthUserModel';
import { TenantDocument } from '../../../database/models/TenantModel';
import { Logger } from '../../Logger';
import { config as configApp } from '../../../config';

export class WompiAdapter implements PaymentGateway {
    private logger = new Logger();

    /**
     * Generates a unique reference for the transaction.
     * Format: TRX-{timestamp}-{random}
     */
    private generateReference(): string {
        const timestamp = Date.now();
        const random = Math.floor(Math.random() * 100000).toString().padStart(5, '0');
        return `TRX-${timestamp}-${random}`;
    }

    /**
     * Calculates the integrity signature required by Wompi.
     * SHA256(Reference + AmountInCents + Currency + IntegritySecret)
     */
    private generateSignature(
        reference: string,
        amountInCents: number,
        currency: string,
        integritySecret: string
    ): string {
        const rawString = `${reference}${amountInCents}${currency}${integritySecret}`;
        return createHash('sha256').update(rawString).digest('hex');
    }

    private getWompiConfig(tenant: TenantDocument) {
        const config = tenant.config?.payments?.wompi;
        if (!config || !config.pubKey || !config.integrityKey) {
            throw new Error('Wompi configuration is missing or incomplete for this tenant.');
        }
        return config;
    }

    private getTransactionsBaseUrl(isTest: boolean): string {
        return isTest
            ? 'https://api-sandbox.wompi.co/v1/transactions/'
            : 'https://api.wompi.co/v1/transactions/';
    }

    async createPaymentIntent(
        amount: number,
        currency: string,
        user: AuthUserDocument,
        tenant: TenantDocument,
        options?: { redirectUrl?: string }
    ): Promise<PaymentIntent> {
        const config = this.getWompiConfig(tenant);
        const reference = this.generateReference();

        // Wompi works with cents for COP
        const amountInCents = Math.round(amount * 100);

        const signature = this.generateSignature(
            reference,
            amountInCents,
            currency,
            config.integrityKey
        );

        this.logger.info(`[WompiAdapter] Created Intent ref: ${reference} for tenant: ${tenant.slug}`);

        // Construct full redirection URL for Mobile/Standard checkout
        const baseUrl = configApp.payments.wompi.checkoutUrl;
        // Ensure base URL ends with / if not present (though regex in Zod should handle, simple safety)
        const safeBaseUrl = baseUrl.endsWith('/') ? baseUrl : `${baseUrl}/`;

        let checkoutUrl = `${safeBaseUrl}?public-key=${config.pubKey}&currency=${currency}&amount-in-cents=${amountInCents}&reference=${reference}&signature:integrity=${signature}`;

        if (options?.redirectUrl) {
            checkoutUrl += `&redirect-url=${encodeURIComponent(options.redirectUrl)}`;
        }

        return {
            reference,
            amount: amountInCents, // Return in cents for Wompi Widget
            currency,
            signature,
            publicKey: config.pubKey,
            checkoutUrl: checkoutUrl,
        };
    }

    async validateTransaction(data: any, tenant: TenantDocument): Promise<PaymentResult> {
        const config = this.getWompiConfig(tenant);

        // Wompi sends { event: '...', data: { transaction: ... }, signature: ... }
        const eventData = data.data.transaction;

        // Verify signature using config.eventsKey if available
        if (config.eventsKey && data.signature && data.signature.checksum) {
            const { checksum } = data.signature;
            const timestamp = data.timestamp;
            const { id, status, amount_in_cents } = eventData;

            // Concatenación según documentación de Wompi: 
            // id + status + amount_in_cents + timestamp + eventsKey
            const rawString = `${id}${status}${amount_in_cents}${timestamp}${config.eventsKey}`;
            const calculatedChecksum = createHash('sha256').update(rawString).digest('hex');

            if (calculatedChecksum !== checksum) {
                this.logger.error('[WompiAdapter] Invalid webhook signature', {
                    reference: eventData.reference,
                    expected: calculatedChecksum,
                    received: checksum
                });
                throw new Error('Invalid signature');
            }
            this.logger.info(`[WompiAdapter] Signature verified for ref: ${eventData.reference}`);
        }

        const statusMap: Record<string, 'APPROVED' | 'DECLINED' | 'VOIDED' | 'ERROR'> = {
            'APPROVED': 'APPROVED',
            'DECLINED': 'DECLINED',
            'VOIDED': 'VOIDED',
            'ERROR': 'ERROR'
        };

        return {
            success: eventData.status === 'APPROVED',
            reference: eventData.reference,
            externalId: eventData.id,
            amount: eventData.amount_in_cents / 100,
            currency: eventData.currency,
            status: statusMap[eventData.status] || 'ERROR',
            metadata: data
        };
    }

    /**
     * Consulta el estado de una transacción directamente en Wompi.
     *
     * @param transactionId - ID de transacción de Wompi.
     * @param tenant - Tenant dueño de la transacción.
     * @returns Estado normalizado de la transacción.
     */
    async getTransactionStatus(
        transactionId: string,
        tenant: TenantDocument,
    ): Promise<PaymentResult> {
        const config = this.getWompiConfig(tenant);
        const baseUrl = this.getTransactionsBaseUrl(Boolean(config.isTest));
        const url = `${baseUrl}${transactionId}`;

        const response = await fetch(url, {
            method: 'GET',
            headers: {
                'Content-Type': 'application/json',
            },
        });

        if (!response.ok) {
            const body = await response.text();
            this.logger.error('[WompiAdapter] Failed to fetch transaction', {
                transactionId,
                status: response.status,
                body,
            });
            throw new Error('Error fetching transaction status');
        }

        const payload = await response.json();
        const transaction = payload?.data;

        if (!transaction || !transaction.status) {
            throw new Error('Invalid Wompi transaction response');
        }

        const statusMap: Record<string, 'APPROVED' | 'DECLINED' | 'VOIDED' | 'ERROR'> = {
            'APPROVED': 'APPROVED',
            'DECLINED': 'DECLINED',
            'VOIDED': 'VOIDED',
            'ERROR': 'ERROR'
        };

        return {
            success: transaction.status === 'APPROVED',
            reference: transaction.reference,
            externalId: transaction.id,
            amount: transaction.amount_in_cents / 100,
            currency: transaction.currency,
            status: statusMap[transaction.status] || 'ERROR',
            metadata: payload,
        };
    }
}

import { AuthUserDocument } from '../../../infrastructure/database/models/AuthUserModel';
import { TenantDocument } from '../../../infrastructure/database/models/TenantModel';

export interface PaymentIntent {
    reference: string;
    amount: number;
    currency: string;
    signature?: string; // Requerido por Wompi
    checkoutUrl?: string; // URL para redirigir al usuario
    publicKey?: string;
    externalId?: string;
}

export interface PaymentResult {
    success: boolean;
    reference: string;
    externalId: string;
    amount: number;
    currency: string;
    status: 'APPROVED' | 'DECLINED' | 'VOIDED' | 'ERROR';
    metadata?: any;
}

export interface PaymentGateway {
    /**
     * Initializes a payment transaction.
     * Generates necessary data for client-side checkout (signature, reference, etc.)
     */
    createPaymentIntent(
        amount: number,
        currency: string,
        user: AuthUserDocument,
        tenant: TenantDocument,
        options?: { redirectUrl?: string }
    ): Promise<PaymentIntent>;

    /**
     * Validates a transaction from a webhook or callback.
     * key can be signature or event data
     */
    validateTransaction(data: any, tenant: TenantDocument): Promise<PaymentResult>;
}

import { WompiAdapter } from '../../infrastructure/services/payment/adapters/WompiAdapter';
import { TenantDocument } from '../../infrastructure/database/models/TenantModel';
import { AuthUserDocument } from '../../infrastructure/database/models/AuthUserModel';
import { Types } from 'mongoose';

describe('WompiAdapter - enableOnlinePayments validation', () => {
    let adapter: WompiAdapter;

    beforeEach(() => {
        adapter = new WompiAdapter();
    });

    describe('getWompiConfig', () => {
        it('should throw error when enableOnlinePayments is false', async () => {
            const tenant = {
                _id: new Types.ObjectId(),
                name: 'Test Tenant',
                slug: 'test-tenant',
                config: {
                    payments: {
                        enableOnlinePayments: false,
                        activeProvider: 'wompi' as const,
                        wompi: {
                            pubKey: 'pub_test_123',
                            eventsKey: 'events_test_123',
                            integrityKey: 'integrity_test_123',
                            isTest: true,
                        },
                    },
                },
            } as TenantDocument;

            const user = {
                _id: new Types.ObjectId(),
                email: 'test@example.com',
                role: 'student',
            } as AuthUserDocument;

            await expect(
                adapter.createPaymentIntent(10000, 'COP', user, tenant)
            ).rejects.toThrow('Online payments are disabled for this tenant.');
        });

        it('should throw error when enableOnlinePayments is undefined', async () => {
            const tenant = {
                _id: new Types.ObjectId(),
                name: 'Test Tenant',
                slug: 'test-tenant',
                config: {
                    payments: {
                        activeProvider: 'wompi' as const,
                        wompi: {
                            pubKey: 'pub_test_123',
                            eventsKey: 'events_test_123',
                            integrityKey: 'integrity_test_123',
                            isTest: true,
                        },
                    },
                },
            } as TenantDocument;

            const user = {
                _id: new Types.ObjectId(),
                email: 'test@example.com',
                role: 'student',
            } as AuthUserDocument;

            await expect(
                adapter.createPaymentIntent(10000, 'COP', user, tenant)
            ).rejects.toThrow('Online payments are disabled for this tenant.');
        });

        it('should succeed when enableOnlinePayments is true and config is valid', async () => {
            const tenant = {
                _id: new Types.ObjectId(),
                name: 'Test Tenant',
                slug: 'test-tenant',
                config: {
                    payments: {
                        enableOnlinePayments: true,
                        activeProvider: 'wompi' as const,
                        wompi: {
                            pubKey: 'pub_test_123',
                            eventsKey: 'events_test_123',
                            integrityKey: 'integrity_test_123',
                            isTest: true,
                        },
                    },
                },
            } as TenantDocument;

            const user = {
                _id: new Types.ObjectId(),
                email: 'test@example.com',
                role: 'student',
            } as AuthUserDocument;

            const result = await adapter.createPaymentIntent(10000, 'COP', user, tenant);

            expect(result).toHaveProperty('reference');
            expect(result).toHaveProperty('signature');
            expect(result).toHaveProperty('publicKey', 'pub_test_123');
            expect(result).toHaveProperty('checkoutUrl');
        });

        it('should throw error when enableOnlinePayments is true but wompi config is missing', async () => {
            const tenant = {
                _id: new Types.ObjectId(),
                name: 'Test Tenant',
                slug: 'test-tenant',
                config: {
                    payments: {
                        enableOnlinePayments: true,
                        activeProvider: 'wompi' as const,
                    },
                },
            } as TenantDocument;

            const user = {
                _id: new Types.ObjectId(),
                email: 'test@example.com',
                role: 'student',
            } as AuthUserDocument;

            await expect(
                adapter.createPaymentIntent(10000, 'COP', user, tenant)
            ).rejects.toThrow('Wompi configuration is missing or incomplete for this tenant.');
        });
    });
});

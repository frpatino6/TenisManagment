import { Types } from 'mongoose';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { StudentTenantModel } from '../../infrastructure/database/models/StudentTenantModel';
import { Logger } from '../../infrastructure/services/Logger';

const logger = new Logger({ module: 'BalanceService' });

/**
 * Service for calculating and managing student balance.
 * 
 * This service calculates balance from the source of truth (Payments and Bookings)
 * rather than relying on the accumulated balance field in StudentTenant.
 * 
 * The balance is calculated as:
 * Balance = Sum of Payments (status: 'paid') - Sum of Bookings (status: 'pending' | 'confirmed' | 'completed')
 * 
 * Note: 'pending' bookings represent debt (reservations created but not yet paid)
 *       'cancelled' bookings are excluded from the calculation
 */
export class BalanceService {
    /**
     * Calculates the actual balance for a student in a tenant from Payments and Bookings.
     * This is the source of truth for balance calculation.
     * 
     * @param studentId - Student ID
     * @param tenantId - Tenant ID
     * @returns The calculated balance
     */
    async calculateBalance(
        studentId: Types.ObjectId | string,
        tenantId: Types.ObjectId | string
    ): Promise<number> {
        const studentObjectId = new Types.ObjectId(studentId.toString());
        const tenantObjectId = new Types.ObjectId(tenantId.toString());

        // Calculate total payments (only paid payments count)
        const paymentsResult = await PaymentModel.aggregate([
            {
                $match: {
                    studentId: studentObjectId,
                    tenantId: tenantObjectId,
                    status: 'paid',
                },
            },
            {
                $group: {
                    _id: null,
                    total: { $sum: '$amount' },
                },
            },
        ]);

        const totalPayments = paymentsResult[0]?.total || 0;

        // Calculate total bookings (pending, confirmed, and completed bookings count as expenses)
        // - 'pending': Reservations created but not yet paid (debt)
        // - 'confirmed': Reservations confirmed (paid or to be paid)
        // - 'completed': Reservations completed
        // - 'cancelled': Should NOT count (cancelled reservations don't affect balance)
        const bookingsResult = await BookingModel.aggregate([
            {
                $match: {
                    studentId: studentObjectId,
                    tenantId: tenantObjectId,
                    status: { $in: ['pending', 'confirmed', 'completed'] },
                },
            },
            {
                $group: {
                    _id: null,
                    total: { $sum: '$price' },
                },
            },
        ]);

        const totalBookings = bookingsResult[0]?.total || 0;

        const calculatedBalance = totalPayments - totalBookings;

        logger.debug('Balance calculated', {
            studentId: studentObjectId.toString(),
            tenantId: tenantObjectId.toString(),
            totalPayments,
            totalBookings,
            calculatedBalance,
        });

        return calculatedBalance;
    }

    /**
     * Gets the balance for a student in a tenant.
     * First calculates from source of truth, then syncs with cached value if different.
     * 
     * @param studentId - Student ID
     * @param tenantId - Tenant ID
     * @param syncCache - If true, updates the cached balance in StudentTenant when different
     * @returns The balance
     */
    async getBalance(
        studentId: Types.ObjectId | string,
        tenantId: Types.ObjectId | string,
        syncCache: boolean = false
    ): Promise<number> {
        const calculatedBalance = await this.calculateBalance(studentId, tenantId);

        if (syncCache) {
            await this.syncBalance(studentId, tenantId, calculatedBalance);
        }

        return calculatedBalance;
    }

    /**
     * Syncs the cached balance in StudentTenant with the calculated balance.
     * This ensures consistency between the cached value and the source of truth.
     * 
     * @param studentId - Student ID
     * @param tenantId - Tenant ID
     * @param calculatedBalance - Optional calculated balance (will be calculated if not provided)
     * @returns The synced balance
     */
    async syncBalance(
        studentId: Types.ObjectId | string,
        tenantId: Types.ObjectId | string,
        calculatedBalance?: number
    ): Promise<number> {
        const studentObjectId = new Types.ObjectId(studentId.toString());
        const tenantObjectId = new Types.ObjectId(tenantId.toString());

        const balance = calculatedBalance ?? await this.calculateBalance(studentId, tenantId);

        // Update cached balance in StudentTenant
        const studentTenant = await StudentTenantModel.findOneAndUpdate(
            {
                studentId: studentObjectId,
                tenantId: tenantObjectId,
            },
            {
                $set: { balance },
                $setOnInsert: { isActive: true, joinedAt: new Date() },
            },
            {
                upsert: true,
                new: true,
            }
        );

        // Log if there was a discrepancy
        if (studentTenant && Math.abs(studentTenant.balance - balance) > 0.01) {
            logger.warn('Balance discrepancy detected and corrected', {
                studentId: studentObjectId.toString(),
                tenantId: tenantObjectId.toString(),
                oldBalance: studentTenant.balance,
                newBalance: balance,
            });
        }

        return balance;
    }

    /**
     * Updates the balance cache after a payment or booking operation.
     * This is a convenience method that should be called after balance-affecting operations.
     * 
     * @param studentId - Student ID
     * @param tenantId - Tenant ID
     * @param delta - The change in balance (positive for payments, negative for bookings)
     * @returns The new balance
     */
    async updateBalanceCache(
        studentId: Types.ObjectId | string,
        tenantId: Types.ObjectId | string,
        delta: number
    ): Promise<number> {
        const studentObjectId = new Types.ObjectId(studentId.toString());
        const tenantObjectId = new Types.ObjectId(tenantId.toString());

        // Update cached balance using $inc
        const studentTenant = await StudentTenantModel.findOneAndUpdate(
            {
                studentId: studentObjectId,
                tenantId: tenantObjectId,
            },
            {
                $inc: { balance: delta },
                $setOnInsert: { isActive: true, joinedAt: new Date() },
            },
            {
                upsert: true,
                new: true,
            }
        );

        return studentTenant?.balance || 0;
    }

    /**
     * Validates that the cached balance matches the calculated balance.
     * If there's a discrepancy, logs a warning and optionally syncs.
     * 
     * @param studentId - Student ID
     * @param tenantId - Tenant ID
     * @param autoSync - If true, automatically syncs when discrepancy is found
     * @returns Object with validation result
     */
    async validateBalance(
        studentId: Types.ObjectId | string,
        tenantId: Types.ObjectId | string,
        autoSync: boolean = false
    ): Promise<{ isValid: boolean; cachedBalance: number; calculatedBalance: number; difference: number }> {
        const studentObjectId = new Types.ObjectId(studentId.toString());
        const tenantObjectId = new Types.ObjectId(tenantId.toString());

        const studentTenant = await StudentTenantModel.findOne({
            studentId: studentObjectId,
            tenantId: tenantObjectId,
        });

        const cachedBalance = studentTenant?.balance || 0;
        const calculatedBalance = await this.calculateBalance(studentId, tenantId);
        const difference = Math.abs(cachedBalance - calculatedBalance);
        const isValid = difference < 0.01; // Allow small floating point differences

        if (!isValid) {
            logger.warn('Balance validation failed', {
                studentId: studentObjectId.toString(),
                tenantId: tenantObjectId.toString(),
                cachedBalance,
                calculatedBalance,
                difference,
            });

            if (autoSync) {
                await this.syncBalance(studentId, tenantId, calculatedBalance);
            }
        }

        return {
            isValid,
            cachedBalance,
            calculatedBalance,
            difference,
        };
    }
}

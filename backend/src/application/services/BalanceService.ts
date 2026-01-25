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
 * Balance = Sum of Recargas (Payments without bookingId) - Sum of Bookings WITHOUT paid payments
 * 
 * Logic:
 * - Only Payments with status 'paid' that are NOT linked to bookings (recargas) are added
 * - Payments linked to bookings are NOT counted here (they're handled in booking logic)
 * - Only Bookings that DON'T have a Payment with status 'paid' associated are subtracted
 * - 'pending' bookings: Always count as debt (no payment yet)
 * - 'confirmed' bookings: Only count if NO payment is associated
 * - 'completed' bookings: Only count if NO payment is associated
 * - 'cancelled' bookings: Excluded from calculation
 * 
 * Note: When a booking is created, balance is deducted. When payment is confirmed for that booking,
 *       the payment should NOT add to balance again (it just cancels the debt).
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
        // IMPORTANT: Only count payments that are NOT linked to bookings (recargas de saldo)
        // Payments linked to bookings are already accounted for in the booking logic
        const paymentsResult = await PaymentModel.aggregate([
            {
                $match: {
                    studentId: studentObjectId,
                    tenantId: tenantObjectId,
                    status: 'paid',
                    $or: [
                        { bookingId: { $exists: false } },
                        { bookingId: null }
                    ]
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

        // Calculate total bookings that are NOT yet paid
        // Only count bookings that don't have a Payment with status 'paid' associated
        // - 'pending': Reservations created but not yet paid (debt)
        // - 'confirmed': Only count if NO payment is associated (unpaid confirmed bookings)
        // - 'completed': Only count if NO payment is associated (unpaid completed bookings)
        // - 'cancelled': Should NOT count (cancelled reservations don't affect balance)
        
        // First, get all bookings
        const allBookings = await BookingModel.find({
            studentId: studentObjectId,
            tenantId: tenantObjectId,
            status: { $in: ['pending', 'confirmed', 'completed'] },
        }).lean();

        // Get all paid payments linked to bookings
        const paidPaymentsForBookings = await PaymentModel.find({
            studentId: studentObjectId,
            tenantId: tenantObjectId,
            status: 'paid',
            bookingId: { $exists: true, $ne: null },
        }).lean();

        // Create a set of booking IDs that have paid payments
        const paidBookingIds = new Set(
            paidPaymentsForBookings
                .map(p => p.bookingId?.toString())
                .filter(id => id !== null && id !== undefined)
        );

        // Calculate total for bookings that don't have paid payments
        const totalBookings = allBookings
            .filter(booking => !paidBookingIds.has(booking._id.toString()))
            .reduce((sum, booking) => sum + booking.price, 0);

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

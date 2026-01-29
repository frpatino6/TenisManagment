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
 * Balance = Recargas (Payments without bookingId) - Deudas (Bookings WITHOUT paid payments) - Gastos con wallet (Payments with bookingId and method='wallet')
 * 
 * Logic:
 * - Recargas: Payments with status 'paid' that are NOT linked to bookings (top-ups)
 * - Deudas: Bookings that DON'T have a Payment with status 'paid' associated
 * - Gastos con wallet: Payments with bookingId and method='wallet' (already deducted from balance when booking was created)
 * 
 * Important:
 * - Payments with method 'wallet' represent expenses already deducted from balance (must subtract)
 * - Payments with other methods (cash, transfer) linked to bookings do NOT add credit
 *   They only cancel the debt of the booking (remove booking from debt calculation)
 *   This is because the booking already deducted the balance when created
 * - 'pending' bookings: Always count as debt (no payment yet)
 * - 'confirmed' bookings: Only count as debt if NO payment is associated
 * - 'completed' bookings: Only count as debt if NO payment is associated
 * - 'cancelled' bookings: Excluded from calculation
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

        // Separate payments by method:
        // - 'wallet': Expenses already deducted from balance (must subtract)
        // - Other methods (cash, transfer): Payments that cancel debt, NOT credits
        const walletPayments = paidPaymentsForBookings.filter(p => p.method === 'wallet');

        // Calculate total wallet expenses (already deducted when booking was created)
        const totalWalletExpenses = walletPayments.reduce((sum, p) => sum + p.amount, 0);

        // Create a set of booking IDs that have paid payments (any method)
        // These bookings are PAID, so they don't count as debt
        const paidBookingIds = new Set(
            paidPaymentsForBookings
                .map(p => p.bookingId?.toString())
                .filter(id => id !== null && id !== undefined)
        );

        // Calculate total for bookings that don't have paid payments (debt)
        // These are unpaid bookings that create debt
        const totalBookings = allBookings
            .filter(booking => !paidBookingIds.has(booking._id.toString()))
            .reduce((sum, booking) => sum + booking.price, 0);

        // IMPORTANT: Payments with method 'cash' or 'transfer' linked to bookings
        // do NOT add credit. They only cancel the debt of the booking.
        // The booking already deducted the balance when created, so the Payment
        // just marks it as paid (removes it from debt calculation).
        // We don't add these payments because:
        // 1. The booking already deducted the balance (created debt)
        // 2. The Payment only cancels that debt (removes booking from debt calculation)
        // 3. Adding the Payment would be double-counting

        // Final balance calculation:
        // Balance = Recargas - Deudas - Gastos con wallet
        // Where:
        // - Recargas: Payments without bookingId (top-ups)
        // - Deudas: Bookings without paid payments (unpaid bookings)
        // - Gastos wallet: Payments with method='wallet' (already deducted)
        // Note: Payments with method='cash'/'transfer' don't add credit, they just cancel debt
        const calculatedBalance = totalPayments - totalBookings - totalWalletExpenses;

        logger.debug('Balance calculated', {
            studentId: studentObjectId.toString(),
            tenantId: tenantObjectId.toString(),
            totalPayments, // Recargas
            totalBookings, // Deudas (bookings sin paid payments)
            totalWalletExpenses, // Gastos con wallet (ya descontados)
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

    /**
     * Calculates balances for all students in a tenant in a single operation.
     * This is significantly more efficient than calling getBalance for each student.
     * 
     * @param tenantId - Tenant ID
     * @returns Map of studentId to balance
     */
    async getBulkBalances(tenantId: Types.ObjectId | string): Promise<Map<string, number>> {
        const tenantObjectId = new Types.ObjectId(tenantId.toString());

        // 1. Aggregate Payments: Total Recargas and Total Wallet Expenses per student
        const paymentsStats = await PaymentModel.aggregate([
            {
                $match: {
                    tenantId: tenantObjectId,
                    status: 'paid'
                }
            },
            {
                $group: {
                    _id: '$studentId',
                    totalRecargas: {
                        $sum: {
                            $cond: [
                                { $or: [{ $eq: ['$bookingId', null] }, { $not: ['$bookingId'] }] },
                                '$amount',
                                0
                            ]
                        }
                    },
                    totalWalletExpenses: {
                        $sum: {
                            $cond: [
                                { $and: [{ $ne: ['$bookingId', null] }, { $eq: ['$method', 'wallet'] }] },
                                '$amount',
                                0
                            ]
                        }
                    }
                }
            }
        ]);

        // 2. Aggregate Bookings: Total Unpaid Bookings per student
        // We need to join with Payments to see which bookings are paid
        const bookingsStats = await BookingModel.aggregate([
            {
                $match: {
                    tenantId: tenantObjectId,
                    status: { $in: ['pending', 'confirmed', 'completed'] }
                }
            },
            {
                $lookup: {
                    from: 'payments',
                    let: { bId: '$_id' },
                    pipeline: [
                        {
                            $match: {
                                $expr: {
                                    $and: [
                                        { $eq: ['$bookingId', '$$bId'] },
                                        { $eq: ['$status', 'paid'] }
                                    ]
                                }
                            }
                        }
                    ],
                    as: 'paidPayments'
                }
            },
            {
                // Unpaid bookings are those that have NO paid payments
                $match: {
                    paidPayments: { $size: 0 }
                }
            },
            {
                $group: {
                    _id: '$studentId',
                    totalUnpaidBookings: { $sum: '$price' }
                }
            }
        ]);

        const result = new Map<string, number>();

        // Create a set of all student IDs seen in either aggregation
        const studentIds = new Set<string>();
        paymentsStats.forEach(s => {
            if (s._id) studentIds.add(s._id.toString());
        });
        bookingsStats.forEach(s => {
            if (s._id) studentIds.add(s._id.toString());
        });

        // Convert stats to lookup maps for easy access
        const paymentsMap = new Map(paymentsStats.map(s => [s._id ? s._id.toString() : '', s]));
        const bookingsMap = new Map(bookingsStats.map(s => [s._id ? s._id.toString() : '', s]));

        // Calculate balance for each student: Recargas - Deudas - WalletExpenses
        for (const sId of studentIds) {
            if (!sId) continue;
            const p = paymentsMap.get(sId);
            const b = bookingsMap.get(sId);

            const recargas = p?.totalRecargas || 0;
            const walletExpenses = p?.totalWalletExpenses || 0;
            const deudas = b?.totalUnpaidBookings || 0;

            result.set(sId, recargas - deudas - walletExpenses);
        }

        return result;
    }
}

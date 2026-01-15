
import { Request, Response } from 'express';
import { TenantAdminController } from '../../application/controllers/TenantAdminController';
import { TenantService } from '../../application/services/TenantService';
import { PaymentModel } from '../../infrastructure/database/models/PaymentModel';
import { BookingModel } from '../../infrastructure/database/models/BookingModel';
import { CourtModel } from '../../infrastructure/database/models/CourtModel';
import { Types } from 'mongoose';

// Mocks
jest.mock('../../application/services/TenantService');
jest.mock('../../infrastructure/database/models/PaymentModel');
jest.mock('../../infrastructure/database/models/BookingModel');
jest.mock('../../infrastructure/database/models/CourtModel');
jest.mock('../../infrastructure/database/models/TenantAdminModel');
jest.mock('../../infrastructure/database/models/ProfessorTenantModel');
jest.mock('../../infrastructure/database/models/StudentTenantModel');
jest.mock('../../infrastructure/services/Logger');

describe('TenantAdminController - Analytics', () => {
    let controller: TenantAdminController;
    let mockTenantService: jest.Mocked<TenantService>;
    let req: Partial<Request>;
    let res: Partial<Response>;
    let jsonMock: jest.Mock;

    beforeEach(() => {
        mockTenantService = new TenantService() as any;
        controller = new TenantAdminController(mockTenantService);
        jsonMock = jest.fn();
        res = {
            status: jest.fn().mockReturnThis(),
            json: jsonMock,
        };
        req = {
            tenantId: '507f1f77bcf86cd799439011',
            query: { period: 'month' }
        };
        jest.clearAllMocks();
    });

    describe('getAnalyticsOverview', () => {
        it('should calculate revenue correctly including pending payments for completed classes', async () => {
            const now = new Date();

            // Mock Data
            const mockPayments = [
                {
                    _id: new Types.ObjectId(),
                    amount: 100,
                    status: 'paid',
                    date: now,
                    bookingId: new Types.ObjectId('507f1f77bcf86cd799439012')
                },
                {
                    _id: new Types.ObjectId(),
                    amount: 50,
                    status: 'pending',
                    date: now,
                    bookingId: new Types.ObjectId('507f1f77bcf86cd799439013')
                }
            ];

            const mockBookings = [
                {
                    _id: new Types.ObjectId('507f1f77bcf86cd799439012'),
                    status: 'confirmed',
                    createdAt: now,
                    bookingDate: now,
                    studentId: new Types.ObjectId(),
                    serviceType: 'individual_class'
                },
                {
                    _id: new Types.ObjectId('507f1f77bcf86cd799439013'),
                    status: 'completed', // pending payment related to this should be counted
                    createdAt: now,
                    bookingDate: now,
                    studentId: new Types.ObjectId(),
                    serviceType: 'group_class'
                }
            ];

            // Setup Mocks
            (PaymentModel.find as jest.Mock).mockReturnValue({
                lean: jest.fn().mockResolvedValue(mockPayments)
            });

            // Need to mock BookingModel.find twice or generic enough
            // 1. for fetching bookings in date range (metrics)
            // 2. for fetching all bookings (charts/cross-check)
            (BookingModel.find as jest.Mock).mockReturnValue({
                select: jest.fn().mockReturnThis(),
                lean: jest.fn().mockResolvedValue(mockBookings)
            });

            (CourtModel.countDocuments as jest.Mock).mockResolvedValue(2);

            // Execute based on request
            await controller.getAnalyticsOverview(req as Request, res as Response);

            // Verify
            expect(jsonMock).toHaveBeenCalled();
            const responseData = jsonMock.mock.calls[0][0];

            // Revenue should be 100 (paid) + 50 (pending but completed) = 150
            const revenueMetric = responseData.metrics.find((m: any) => m.title === 'Ingresos del Período');
            expect(revenueMetric.value).toBe('$150');

            // Verify Charts presence
            expect(responseData.charts).toBeDefined();
            expect(responseData.charts.length).toBe(2);
            expect(responseData.charts[0].title).toBe('Ingresos'); // Revenue chart
        });
    });
});

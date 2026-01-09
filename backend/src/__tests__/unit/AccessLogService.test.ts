import { AccessLogService } from '../../domain/services/AccessLogService';
import { AccessLogModel } from '../../infrastructure/database/models/AccessLogModel';
import { Types } from 'mongoose';

// Mock AccessLogModel
jest.mock('../../infrastructure/database/models/AccessLogModel');

describe('AccessLogService', () => {
    beforeEach(() => {
        jest.clearAllMocks();
    });

    describe('logAccess', () => {
        it('should create an access log entry successfully', async () => {
            const logData = {
                userId: new Types.ObjectId(),
                email: 'test@example.com',
                role: 'student',
                action: 'LOGIN',
                ip: '127.0.0.1',
                userAgent: 'Mozilla/5.0',
                metadata: { some: 'data' }
            };

            (AccessLogModel.create as jest.Mock).mockResolvedValue(logData);

            await AccessLogService.logAccess(logData);

            expect(AccessLogModel.create).toHaveBeenCalledWith({
                userId: expect.any(Types.ObjectId),
                email: logData.email,
                role: logData.role,
                action: logData.action,
                ip: logData.ip,
                userAgent: logData.userAgent,
                metadata: logData.metadata,
            });
        });

        it('should handle errors gracefully without throwing', async () => {
            const logData = {
                userId: new Types.ObjectId(),
                email: 'test@example.com',
                role: 'student',
                action: 'LOGIN'
            };

            const error = new Error('Database connection failed');
            (AccessLogModel.create as jest.Mock).mockRejectedValue(error);

            // Should not throw
            await expect(AccessLogService.logAccess(logData)).resolves.not.toThrow();

            expect(AccessLogModel.create).toHaveBeenCalled();
            // Logger.error is called internally, but we might verify it if we mocked Logger.
            // Since Logger is a private static property initialized inside the class, verifying it is harder 
            // without deeper mocking, but the key behavior is "not throwing".
        });
    });
});

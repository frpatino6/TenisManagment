import { AccessLogModel } from '../../infrastructure/database/models/AccessLogModel';
import { Logger } from '../../infrastructure/services/Logger';
import { Types } from 'mongoose';

interface CreateAccessLogDTO {
    userId: string | Types.ObjectId;
    email: string;
    role: string;
    action: string;
    ip?: string;
    userAgent?: string;
    metadata?: Record<string, any>;
}

export class AccessLogService {
    private static logger = new Logger({ service: 'AccessLogService' });

    /**
     * Creates a new access log entry
     * Errors are logged but do not throw, to avoid blocking the main auth flow
     */
    static async logAccess(data: CreateAccessLogDTO): Promise<void> {
        try {
            await AccessLogModel.create({
                userId: new Types.ObjectId(data.userId),
                email: data.email,
                role: data.role,
                action: data.action,
                ip: data.ip,
                userAgent: data.userAgent,
                metadata: data.metadata,
            });
            AccessLogService.logger.debug(`Access log created for ${data.email} [${data.action}]`);
        } catch (error) {
            AccessLogService.logger.error('Failed to create access log', {
                error: error instanceof Error ? error.message : String(error)
            });
            // We do NOT rethrow, as logging failure shouldn't fail the user request
        }
    }
}

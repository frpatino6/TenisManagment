import { Schema, model, Types } from 'mongoose';

export interface AccessLogDocument {
    _id: Types.ObjectId;
    userId: Types.ObjectId;
    email: string;
    role: string;
    action: string;
    ip?: string;
    userAgent?: string;
    metadata?: Record<string, any>;
    createdAt: Date;
}

const AccessLogSchema = new Schema<AccessLogDocument>(
    {
        userId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, index: true },
        email: { type: String, required: true },
        role: { type: String, required: true },
        action: { type: String, required: true }, // e.g., 'LOGIN', 'VERIFY_TOKEN'
        ip: { type: String },
        userAgent: { type: String },
        metadata: { type: Object },
    },
    { timestamps: { createdAt: true, updatedAt: false } }, // Only createdAt is needed for logs
);

// Index for time-range queries
AccessLogSchema.index({ createdAt: -1 });

export const AccessLogModel = model<AccessLogDocument>('AccessLog', AccessLogSchema);

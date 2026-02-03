import { Schema, model, Types, Document } from 'mongoose';

export interface UserRankingDocument extends Document {
    userId: Types.ObjectId;
    tenantId: Types.ObjectId;
    eloScore: number;
    monthlyRacePoints: number;
    totalMatches: number;
    winRate: number;
    lastResetDate: Date;
    createdAt: Date;
    updatedAt: Date;
}

const UserRankingSchema = new Schema<UserRankingDocument>({
    userId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, index: true },
    tenantId: { type: Schema.Types.ObjectId, ref: 'Tenant', required: true, index: true },
    eloScore: { type: Number, default: 1200 },
    monthlyRacePoints: { type: Number, default: 0 },
    totalMatches: { type: Number, default: 0 },
    winRate: { type: Number, default: 0 },
    lastResetDate: { type: Date, default: Date.now }
}, { timestamps: true });

// Composite indexes for efficient ranking queries per club
UserRankingSchema.index({ tenantId: 1, eloScore: -1 });
UserRankingSchema.index({ tenantId: 1, monthlyRacePoints: -1 });
UserRankingSchema.index({ tenantId: 1, userId: 1 }, { unique: true });

export const UserRankingModel = model<UserRankingDocument>('UserRanking', UserRankingSchema);

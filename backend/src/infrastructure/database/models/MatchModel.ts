import { Schema, model, Document, Types } from 'mongoose';

export interface MatchDocument extends Document {
    tenantId: Types.ObjectId;
    winnerId: Types.ObjectId;
    loserId: Types.ObjectId;
    score: string;
    date: Date;
    isTournament: boolean;
    isOffPeak: boolean;
    isMatchmakingChallenge: boolean;
    metadata?: Record<string, any>;
    createdAt: Date;
    updatedAt: Date;
}

const MatchSchema = new Schema<MatchDocument>(
    {
        tenantId: { type: Schema.Types.ObjectId, ref: 'Tenant', required: true, index: true },
        winnerId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, index: true },
        loserId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true, index: true },
        score: { type: String, required: true },
        date: { type: Date, required: true, default: Date.now },
        isTournament: { type: Boolean, default: false },
        isOffPeak: { type: Boolean, default: false },
        isMatchmakingChallenge: { type: Boolean, default: false },
        metadata: { type: Schema.Types.Mixed },
    },
    {
        timestamps: true,
    }
);

// Índice compuesto para búsquedas de historial de enfrentamientos
MatchSchema.index({ tenantId: 1, date: -1 });
MatchSchema.index({ winnerId: 1, loserId: 1 });

export const MatchModel = model<MatchDocument>('Match', MatchSchema);

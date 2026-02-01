import { Schema, model, Document, Types } from 'mongoose';

export interface TournamentDocument extends Document {
    tenantId: Types.ObjectId;
    name: string;
    description: string;
    startDate: Date;
    endDate: Date;
    status: 'DRAFT' | 'IN_PROGRESS' | 'FINISHED' | 'CANCELLED';
    categories: Array<{
        _id: Types.ObjectId;
        name: string;
        gender: 'MALE' | 'FEMALE' | 'MIXED';
        minElo?: number;
        maxElo?: number;
        participants: Types.ObjectId[];
        format: 'SINGLE_ELIMINATION' | 'ROUND_ROBIN' | 'HYBRID';
        groupStageConfig?: {
            numberOfGroups: number;
            advancePerGroup: number;
            pointsForWin: number;
            pointsForDraw: number;
            pointsForLoss: number;
            seedingMethod: 'RANKING' | 'RANDOM' | 'MANUAL';
        };
        hasGroupStage: boolean;
        hasBracket: boolean;
    }>;
    metadata?: Record<string, any>;
    createdAt: Date;
    updatedAt: Date;
}

const CategorySchema = new Schema({
    name: { type: String, required: true },
    gender: {
        type: String,
        enum: ['MALE', 'FEMALE', 'MIXED'],
        default: 'MIXED',
        required: true
    },
    minElo: { type: Number },
    maxElo: { type: Number },
    participants: [{ type: Schema.Types.ObjectId, ref: 'AuthUser' }],

    // Configuración de formato
    format: {
        type: String,
        enum: ['SINGLE_ELIMINATION', 'ROUND_ROBIN', 'HYBRID'],
        default: 'SINGLE_ELIMINATION',
        required: true
    },

    // Configuración de fase de grupos
    groupStageConfig: {
        numberOfGroups: { type: Number },
        advancePerGroup: { type: Number },
        pointsForWin: { type: Number, default: 3 },
        pointsForDraw: { type: Number, default: 1 },
        pointsForLoss: { type: Number, default: 0 },
        seedingMethod: {
            type: String,
            enum: ['RANKING', 'RANDOM', 'MANUAL'],
            default: 'RANKING'
        }
    },

    // Referencias a las fases
    hasGroupStage: { type: Boolean, default: false },
    hasBracket: { type: Boolean, default: false },
});

const TournamentSchema = new Schema<TournamentDocument>(
    {
        tenantId: { type: Schema.Types.ObjectId, ref: 'Tenant', required: true, index: true },
        name: { type: String, required: true },
        description: { type: String },
        startDate: { type: Date, required: true },
        endDate: { type: Date, required: true },
        status: {
            type: String,
            enum: ['DRAFT', 'IN_PROGRESS', 'FINISHED', 'CANCELLED'],
            default: 'DRAFT',
            required: true
        },
        categories: [CategorySchema],
        metadata: { type: Schema.Types.Mixed },
    },
    {
        timestamps: true,
    }
);

TournamentSchema.index({ tenantId: 1, status: 1 });
TournamentSchema.index({ tenantId: 1, startDate: -1 });

export const TournamentModel = model<TournamentDocument>('Tournament', TournamentSchema);

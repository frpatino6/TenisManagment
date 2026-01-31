import { Schema, model, Document, Types } from 'mongoose';

export interface GroupStageDocument extends Document {
    tournamentId: Types.ObjectId;
    categoryId: string;
    groups: Array<{
        id: string;
        name: string;
        seed: number;
        participants: Types.ObjectId[];
        matches: Array<{
            id: string;
            groupId: string;
            player1Id: Types.ObjectId;
            player1Name?: string;
            player1Elo?: number;
            player2Id: Types.ObjectId;
            player2Name?: string;
            player2Elo?: number;
            winnerId?: Types.ObjectId;
            score?: string;
            matchDate?: Date;
            round?: number;
        }>;
        standings: Array<{
            playerId: Types.ObjectId;
            playerName?: string;
            playerElo?: number;
            position: number;
            matchesPlayed: number;
            wins: number;
            draws: number;
            losses: number;
            points: number;
            setsWon: number;
            setsLost: number;
            gamesWon: number;
            gamesLost: number;
            setDifference: number;
            gameDifference: number;
            qualifiedForKnockout: boolean;
        }>;
    }>;
    status: 'DRAFT' | 'LOCKED' | 'IN_PROGRESS' | 'COMPLETED';
    createdAt: Date;
    updatedAt: Date;
}

const GroupStageMatchSchema = new Schema({
    id: { type: String, required: true },
    groupId: { type: String, required: true },
    player1Id: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true },
    player1Name: { type: String },
    player1Elo: { type: Number },
    player2Id: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true },
    player2Name: { type: String },
    player2Elo: { type: Number },
    winnerId: { type: Schema.Types.ObjectId, ref: 'AuthUser' },
    score: { type: String },
    matchDate: { type: Date },
    round: { type: Number },
}, { _id: false });

const GroupStandingSchema = new Schema({
    playerId: { type: Schema.Types.ObjectId, ref: 'AuthUser', required: true },
    playerName: { type: String },
    playerElo: { type: Number },
    position: { type: Number, required: true },
    matchesPlayed: { type: Number, default: 0 },
    wins: { type: Number, default: 0 },
    draws: { type: Number, default: 0 },
    losses: { type: Number, default: 0 },
    points: { type: Number, default: 0 },
    setsWon: { type: Number, default: 0 },
    setsLost: { type: Number, default: 0 },
    gamesWon: { type: Number, default: 0 },
    gamesLost: { type: Number, default: 0 },
    setDifference: { type: Number, default: 0 },
    gameDifference: { type: Number, default: 0 },
    qualifiedForKnockout: { type: Boolean, default: false },
}, { _id: false });

const GroupSchema = new Schema({
    id: { type: String, required: true },
    name: { type: String, required: true },
    seed: { type: Number, required: true },
    participants: [{ type: Schema.Types.ObjectId, ref: 'AuthUser' }],
    matches: [GroupStageMatchSchema],
    standings: [GroupStandingSchema],
}, { _id: false });

const GroupStageSchema = new Schema<GroupStageDocument>(
    {
        tournamentId: { type: Schema.Types.ObjectId, ref: 'Tournament', required: true, index: true },
        categoryId: { type: String, required: true, index: true },
        groups: [GroupSchema],
        status: {
            type: String,
            enum: ['DRAFT', 'LOCKED', 'IN_PROGRESS', 'COMPLETED'],
            default: 'DRAFT',
            required: true
        },
    },
    {
        timestamps: true,
    }
);

GroupStageSchema.index({ tournamentId: 1, categoryId: 1 }, { unique: true });
GroupStageSchema.index({ status: 1 });

export const GroupStageModel = model<GroupStageDocument>('GroupStage', GroupStageSchema);

import mongoose, { Schema, Document } from 'mongoose';
import { Bracket, BracketMatch, BracketStatus } from '../../../domain/entities/Bracket';

interface BracketDocument extends Document {
    tournamentId: string;
    categoryId: string;
    matches: BracketMatch[];
    status: BracketStatus;
    createdAt: Date;
    updatedAt: Date;
}

const BracketMatchSchema = new Schema<BracketMatch>({
    id: { type: String, required: true },
    round: { type: Number, required: true },
    position: { type: Number, required: true },
    player1Id: { type: String, required: false },
    player1Name: { type: String, required: false },
    player2Id: { type: String, required: false },
    player2Name: { type: String, required: false },
    winnerId: { type: String, required: false },
    winnerName: { type: String, required: false },
    score: { type: String, required: false },
    nextMatchId: { type: String, required: false },
    matchDate: { type: Date, required: false }
}, { _id: false });

const BracketSchema = new Schema<BracketDocument>({
    tournamentId: { type: String, required: true, index: true },
    categoryId: { type: String, required: true, index: true },
    matches: { type: [BracketMatchSchema], required: true },
    status: {
        type: String,
        enum: ['PENDING', 'IN_PROGRESS', 'COMPLETED'],
        required: true,
        default: 'PENDING'
    }
}, {
    timestamps: true
});

// Índice compuesto para búsquedas por torneo y categoría
BracketSchema.index({ tournamentId: 1, categoryId: 1 }, { unique: true });

export const BracketModel = mongoose.model<BracketDocument>('Bracket', BracketSchema);

import { Types } from 'mongoose';
import { Match } from '../../domain/entities/Match';
import { IMatchRepository } from '../../domain/repositories/IMatchRepository';
import { MatchModel, MatchDocument } from '../database/models/MatchModel';

export class MongoMatchRepository implements IMatchRepository {
    async save(match: Match): Promise<Match> {
        const doc = new MatchModel({
            ...match,
            tenantId: new Types.ObjectId(match.tenantId),
            winnerId: new Types.ObjectId(match.winnerId),
            loserId: new Types.ObjectId(match.loserId),
        });
        const saved = await doc.save();
        return this.mapToEntity(saved);
    }

    async findById(id: string): Promise<Match | null> {
        const doc = await MatchModel.findById(id).lean();
        return doc ? this.mapToEntity(doc as any) : null;
    }

    async findByTenant(tenantId: string, limit: number = 20): Promise<Match[]> {
        const docs = await MatchModel.find({ tenantId: new Types.ObjectId(tenantId) })
            .sort({ date: -1 })
            .limit(limit)
            .lean();
        return docs.map(doc => this.mapToEntity(doc as any));
    }

    async findByUser(userId: string, tenantId: string): Promise<Match[]> {
        const docs = await MatchModel.find({
            tenantId: new Types.ObjectId(tenantId),
            $or: [
                { winnerId: new Types.ObjectId(userId) },
                { loserId: new Types.ObjectId(userId) }
            ]
        })
            .sort({ date: -1 })
            .lean();
        return docs.map(doc => this.mapToEntity(doc as any));
    }

    private mapToEntity(doc: MatchDocument): Match {
        return {
            id: doc._id.toString(),
            tenantId: doc.tenantId.toString(),
            winnerId: doc.winnerId.toString(),
            loserId: doc.loserId.toString(),
            score: doc.score,
            date: doc.date,
            isTournament: doc.isTournament,
            isOffPeak: doc.isOffPeak,
            isMatchmakingChallenge: doc.isMatchmakingChallenge,
            metadata: doc.metadata
        };
    }
}
